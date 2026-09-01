class_name Dynamite
extends RigidBody2D

@export var explosion_radius: float = 48.0
@export var explosion_start_radius: float = 4.0
@export var explosion_expand_duration: float = 0.2
@export var explosion_damage: float = 10.0
@export var explosion_impulse: float = 150.0
@export var chain_radius: float = 56.0
@export var connected_dynamites: Array[NodePath] = []
@export var cleanup_delay: float = 0.35

signal target_destroyed(target)

var has_exploded := false

@onready var dynamite_sprite: Sprite2D = $DynamiteSprite
@onready var explosion_sprite: Sprite2D = $ExplosionSprite
@onready var explosion_audio: AudioStreamPlayer = $Explosion

func _ready() -> void:
	add_to_group("dynamite")
	add_to_group("explosive")
	if is_instance_valid(explosion_sprite):
		explosion_sprite.visible = false
		explosion_sprite.frame = 0

func explode() -> void:
	if has_exploded:
		return

	has_exploded = true
	_stop_physics()
	_disable_collisions()
	_expand_explosion_hitbox()
	_chain_connected_dynamite()
	_play_explosion()
	target_destroyed.emit(self)

	await get_tree().create_timer(maxf(cleanup_delay, explosion_expand_duration)).timeout
	queue_free()

func handle_death() -> void:
	explode()

func _stop_physics() -> void:
	set_deferred("freeze", true)
	set_deferred("sleeping", true)
	set_deferred("linear_velocity", Vector2.ZERO)
	set_deferred("angular_velocity", 0.0)
	set_deferred("gravity_scale", 0.0)

func _disable_collisions() -> void:
	for collision_shape in find_children("*", "CollisionShape2D", true, false):
		if collision_shape is CollisionShape2D:
			collision_shape.set_deferred("disabled", true)

func _expand_explosion_hitbox() -> void:
	var damaged_nodes: Array[Node] = []
	var shoved_nodes: Array[Node] = []
	var elapsed := 0.0

	while elapsed < explosion_expand_duration:
		var progress := elapsed / explosion_expand_duration if explosion_expand_duration > 0.0 else 1.0
		var current_radius := lerpf(explosion_start_radius, explosion_radius, clampf(progress, 0.0, 1.0))
		_damage_nearby_targets(current_radius, damaged_nodes, shoved_nodes)
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()

	_damage_nearby_targets(explosion_radius, damaged_nodes, shoved_nodes)

func _damage_nearby_targets(current_radius: float, damaged_nodes: Array[Node], shoved_nodes: Array[Node]) -> void:
	var shape := CircleShape2D.new()
	shape.radius = maxf(current_radius, 0.0)

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var collider := result.get("collider") as Node
		if collider == null or collider == self:
			continue
		if collider.get_parent() == self:
			continue

		var impulse_body := _get_impulse_body(collider)
		if impulse_body != null and not shoved_nodes.has(impulse_body):
			shoved_nodes.append(impulse_body)
			_apply_explosion_impulse(collider)

		if collider is Area2D and collider.is_in_group("hitbox"):
			if damaged_nodes.has(collider):
				continue
			damaged_nodes.append(collider)
			var attack := Attack.new()
			attack.attack_damage = explosion_damage
			collider.damage(attack)

func _get_impulse_body(collider: Node) -> Node:
	var body := collider
	if collider is Area2D and collider.get_parent() != null:
		body = collider.get_parent()
	return body

func _apply_explosion_impulse(collider: Node) -> void:
	var body := _get_impulse_body(collider)

	if body is Node and body.is_in_group("target"):
		return
	if body is Node and body.is_in_group("dynamite"):
		return

	if body is RigidBody2D:
		var rigid_body := body as RigidBody2D
		var shove_direction := rigid_body.global_position - global_position
		if shove_direction == Vector2.ZERO:
			shove_direction = Vector2.UP
		rigid_body.call_deferred("apply_central_impulse", shove_direction.normalized() * explosion_impulse)
	elif body is CharacterBody2D and "velocity" in body:
		var character := body as CharacterBody2D
		var shove_direction := character.global_position - global_position
		if shove_direction == Vector2.ZERO:
			shove_direction = Vector2.UP
		character.velocity += shove_direction.normalized() * explosion_impulse

func _chain_connected_dynamite() -> void:
	for dynamite_path: NodePath in connected_dynamites:
		var dynamite := get_node_or_null(dynamite_path)
		if dynamite != null and dynamite != self and dynamite.has_method("explode"):
			dynamite.explode()

	for node: Node in get_tree().get_nodes_in_group("dynamite"):
		if node == self or not (node is Node2D):
			continue
		if global_position.distance_to((node as Node2D).global_position) > chain_radius:
			continue
		if node.has_method("explode"):
			node.explode()

func _play_explosion() -> void:
	if is_instance_valid(dynamite_sprite):
		dynamite_sprite.visible = false

	_play_explosion_sound()

	if not is_instance_valid(explosion_sprite):
		return

	explosion_sprite.visible = true
	explosion_sprite.frame = 0
	var tween := create_tween()
	tween.tween_property(explosion_sprite, "frame", 15, cleanup_delay)

func _configure_audio_for_bullet_time(audio_player: AudioStreamPlayer) -> void:
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("configure_audio_player_for_bullet_time"):
		game_manager.configure_audio_player_for_bullet_time(audio_player)

func _play_explosion_sound() -> void:
	if not is_instance_valid(explosion_audio) or explosion_audio.stream == null:
		return

	var owner := get_parent()
	if owner == null:
		return

	var detached_audio := AudioStreamPlayer.new()
	detached_audio.stream = explosion_audio.stream
	detached_audio.bus = explosion_audio.bus
	owner.add_child(detached_audio)
	_configure_audio_for_bullet_time(detached_audio)
	detached_audio.finished.connect(detached_audio.queue_free)
	detached_audio.play()

extends "res://Scripts/lock_box.gd"

@export var bouncy_burst_scene: PackedScene
@export var bouncy_burst_radius := 72.0
@export var bouncy_burst_impulse := 520.0
@export var bouncy_burst_upward_bias := 0.35
@export_range(0.0, 1.0, 0.05) var bouncy_burst_min_force_scale := 0.65
@export var limit_stacked_upward_launch := true
@export var idle_animation_name: StringName = &"animation"
@export var randomize_idle_animation_start := true

@onready var idle_animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

func _ready() -> void:
	super._ready()
	_randomize_idle_animation_start()

func _bullet_entered_check(body: Node2D) -> void:
	if is_unlocked or body.is_queued_for_deletion():
		return
	if not body.is_in_group(second_pickup_group):
		return
	if body.get("has_key") != true:
		return

	_ricochet_key_bullet(body)
	unlock()

func _on_unlocked() -> void:
	_spawn_bouncy_burst()
	_apply_bouncy_burst_knockback()

func _randomize_idle_animation_start() -> void:
	if not randomize_idle_animation_start:
		return
	if not is_instance_valid(idle_animation_player):
		return
	if not idle_animation_player.has_animation(idle_animation_name):
		return

	var animation_length := idle_animation_player.get_animation(idle_animation_name).length
	if animation_length <= 0.0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%s" % [get_path(), Time.get_ticks_usec()])
	idle_animation_player.play(idle_animation_name)
	idle_animation_player.seek(rng.randf_range(0.0, animation_length), true)

func _ricochet_key_bullet(body: Node2D) -> void:
	if not ("direction" in body):
		return

	var bullet_direction: Vector2 = body.get("direction")
	var bounce_normal := (body.global_position - global_position).normalized()
	if bounce_normal == Vector2.ZERO:
		bounce_normal = -bullet_direction.normalized()

	var ricochet_direction := bullet_direction.bounce(bounce_normal).normalized()
	body.set("direction", ricochet_direction)
	body.rotation = ricochet_direction.angle()

	if "bounce_count" in body:
		var max_bounces := int(body.get("max_bounces")) if "max_bounces" in body else int(body.get("bounce_count")) + 1
		body.set("bounce_count", maxi(max_bounces, 1))
	if body.has_method("_play_ricochet"):
		body._play_ricochet()

func _spawn_bouncy_burst() -> void:
	if bouncy_burst_scene == null:
		return

	var burst := bouncy_burst_scene.instantiate() as Node2D
	if burst == null:
		return

	var parent_node := get_parent()
	if parent_node == null:
		return

	parent_node.add_child(burst)
	burst.global_position = global_position

func _apply_bouncy_burst_knockback() -> void:
	var shape := CircleShape2D.new()
	shape.radius = maxf(bouncy_burst_radius, 0.0)

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var shoved_bodies: Array[Node] = []
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var body := result.get("collider") as Node
		if body == null or body == self or shoved_bodies.has(body):
			continue
		if not body.is_in_group("player") and not body.is_in_group("enemy"):
			continue

		shoved_bodies.append(body)
		_apply_bouncy_burst_impulse(body)

func _apply_bouncy_burst_impulse(body: Node) -> void:
	if not (body is Node2D):
		return

	var body_2d := body as Node2D
	var shove_direction := body_2d.global_position - global_position
	if shove_direction == Vector2.ZERO:
		shove_direction = Vector2.UP

	var distance := minf(shove_direction.length(), bouncy_burst_radius)
	var falloff := 1.0 - (distance / maxf(bouncy_burst_radius, 1.0))
	var impulse_direction := shove_direction.normalized()
	impulse_direction.y -= bouncy_burst_upward_bias
	var impulse := impulse_direction.normalized() * bouncy_burst_impulse * maxf(falloff, bouncy_burst_min_force_scale)
	impulse = _limit_stacked_upward_impulse(body, impulse)

	if body.has_method("apply_explosion_knockback"):
		body.apply_explosion_knockback(impulse)
	elif body is CharacterBody2D:
		var character := body as CharacterBody2D
		character.velocity += impulse
		if "knockedback" in character:
			character.set("knockedback", true)

func _limit_stacked_upward_impulse(body: Node, impulse: Vector2) -> Vector2:
	if not limit_stacked_upward_launch:
		return impulse
	if impulse.y >= 0.0:
		return impulse
	if not (body is CharacterBody2D):
		return impulse

	var character := body as CharacterBody2D
	if character.velocity.y >= 0.0:
		return impulse

	var target_upward_velocity := impulse.y
	var needed_upward_impulse := target_upward_velocity - character.velocity.y
	impulse.y = minf(needed_upward_impulse, 0.0)
	return impulse

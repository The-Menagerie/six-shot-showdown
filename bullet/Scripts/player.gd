extends CharacterBody2D

@export var move_speed : float = 200.0
@export var jump_force : float = 300.0
@export var gravity : float = 900.0
@export var starting_direction : float = 1.0
@export var revolver_rest_position : Vector2 = Vector2(0, 6)
@export var recoil_distance : float = 6.0
@export var recoil_return_speed : float = 22.0
@export var player_recoil_force : float = 260.0
@export var recoil_velocity_decay : float = 700.0
@export var vertical_recoil_scale : float = 0.45
const BULLET_SCENE = preload("res://Scenes/Objects/Bullets/bullet.tscn")

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine = animation_tree["parameters/playback"]
@onready var revolver: Node2D = $Revolver
@onready var muzzle: Marker2D = $Revolver/Muzzle
@onready var gunshot_audio: AudioStreamPlayer = $Revolver/AudioStreamPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var facing_direction : float = 1.0
var recoil_offset : Vector2 = Vector2.ZERO
var recoil_velocity : Vector2 = Vector2.ZERO
var has_key := false
var flying := false
var just_shot := false

func _ready():
	add_to_group("player")
	animation_tree.active = true
	facing_direction = starting_direction if starting_direction != 0 else 1.0
	animation_tree.set("parameters/Idle/blend_position", facing_direction)
	animation_tree.set("parameters/Walk/blend_position", facing_direction)
	revolver.position = revolver_rest_position
	BulletBus.fire_player_bullet.connect(fire_bullet)

func _physics_process(delta):
	var move_input = Input.get_axis("left", "right")
	var jump_pressed = Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept")

	if jump_pressed and is_on_floor():
		velocity.y = -jump_force
	elif not is_on_floor():
		velocity.y += gravity * delta
	
	if just_shot:
		velocity.y += recoil_velocity.y*2
		just_shot = false

	recoil_velocity = recoil_velocity.move_toward(Vector2.ZERO, recoil_velocity_decay * delta)
	velocity.x = move_input * move_speed + recoil_velocity.x


	move_and_slide()
	if flying:
		ram_through()
		if is_on_floor():
			self.modulate = Color(1,1,1,1)
			_set_flying_state(false)
	_push_boulders()
	update_animation_parameters()
	update_revolver_aim()
	update_revolver_recoil(delta)
	#fire_bullet()
	pick_new_state()

func update_animation_parameters():
	var mouse_position = get_global_mouse_position()
	var aim_vector = mouse_position - global_position
	if aim_vector.x != 0:
		facing_direction = 1.0 if aim_vector.x > 0 else -1.0
	animation_tree.set("parameters/Walk/blend_position", facing_direction)
	animation_tree.set("parameters/Idle/blend_position", facing_direction)
	animation_tree.set("parameters/Jump/blend_position", facing_direction)

func update_revolver_aim():
	var mouse_position = get_global_mouse_position()
	var aim_vector = mouse_position - global_position
	var angle = atan2(aim_vector.y, aim_vector.x)

	if aim_vector.x < 0:
		revolver.scale.x = -1.0
		revolver.rotation = angle - PI
	else:
		revolver.scale.x = 1.0
		revolver.rotation = angle

	revolver.position = revolver_rest_position + recoil_offset

func update_revolver_recoil(delta):
	recoil_offset = recoil_offset.move_toward(Vector2.ZERO, recoil_return_speed * delta)

func fire_bullet(bullet_scene: PackedScene):
	#if Input.is_action_just_pressed("shoot"):
	var bullet = bullet_scene.instantiate()
	bullet.shooter = self
	ScoreBus.player_fired_shot()
	if bullet.has_method("capture_swap_origin"):
		bullet.capture_swap_origin(self)
	var aim_vector = get_global_mouse_position() - global_position
	revolver.add_child(bullet)
	bullet.position = muzzle.position
	var world_parent := get_parent()
	if world_parent != null:
		revolver.remove_child(bullet)
		world_parent.add_child(bullet)
		bullet.global_position = muzzle.global_position
	bullet.add_collision_exception_with(self)
	bullet.set_direction(aim_vector)
	if bullet.has_method("arm"):
		bullet.arm()
	apply_revolver_kickback(aim_vector)
	if "recoil_multiplier" in bullet:
		apply_player_kickback(aim_vector, bullet.recoil_multiplier)
		if bullet.recoil_multiplier >= 1.5:
			_set_flying_state(true)
	else:
		apply_player_kickback(aim_vector)
	gunshot_audio.play()

func apply_revolver_kickback(aim_vector: Vector2):
	if aim_vector == Vector2.ZERO:
		return

	recoil_offset = -aim_vector.normalized() * recoil_distance

func apply_player_kickback(aim_vector: Vector2, recoil_multiplier: float = 1.0):
	if aim_vector == Vector2.ZERO:
		return

	var recoil_impulse = -aim_vector.normalized() * player_recoil_force * recoil_multiplier
	recoil_impulse.y *= vertical_recoil_scale
	recoil_velocity += recoil_impulse
	just_shot = true

func collect_key() -> void:
	has_key = true

func _push_boulders() -> void:
	for collision_index in range(get_slide_collision_count()):
		var collision = get_slide_collision(collision_index)
		var collider = collision.get_collider()
		if collider == null:
			continue
		if collision.get_normal().y <= -0.85 and collider.has_method("push_from_below_by_player"):
			var bottom_push_direction := Vector2(velocity.x, -1.0)
			if bottom_push_direction.x == 0.0:
				bottom_push_direction.x = facing_direction
			collider.push_from_below_by_player(bottom_push_direction)
			continue
		if not collider.has_method("push_by_player"):
			continue
		if abs(collision.get_normal().x) < 0.85:
			continue

		var push_direction := Vector2(velocity.x, 0.0)
		if push_direction == Vector2.ZERO:
			push_direction = -collision.get_normal()
			push_direction.y = 0.0

		if push_direction != Vector2.ZERO:
			collider.push_by_player(push_direction)

func pick_new_state():
	if not is_on_floor():
		state_machine.travel("Jump")
	elif abs(velocity.x) > 0.1:
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")

func _set_flying_state(enabled: bool) -> void:
	if flying == enabled:
		return

	flying = enabled
	modulate = Color(0.5,0.5,1,1) if enabled else Color(1,1,1,1)

	for node in get_tree().get_nodes_in_group("breakable"):
		if node.has_method("set_player_collision_enabled"):
			node.set_player_collision_enabled(not enabled, self)

func ram_through() -> void:
	var hit_areas: Dictionary = {}

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		_register_ram_target(collision.get_collider(), hit_areas)

	for area in _get_fly_overlap_hitboxes():
		_register_ram_target(area, hit_areas)

	for area in hit_areas.keys():
		var attack := Attack.new()
		attack.attack_damage = 1.0
		area.damage(attack)

func _get_fly_overlap_hitboxes() -> Array[Area2D]:
	var results: Array[Area2D] = []
	if not is_instance_valid(collision_shape) or collision_shape.shape == null:
		return results

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = collision_shape.global_transform
	query.exclude = [self]
	query.collide_with_bodies = false
	query.collide_with_areas = true

	for result in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var collider = result.get("collider")
		if collider is Area2D and collider.is_in_group("hitbox"):
			results.append(collider)

	return results

func _register_ram_target(collider: Variant, hit_areas: Dictionary) -> void:
	if collider == null:
		return

	if collider is Area2D and collider.is_in_group("hitbox"):
		hit_areas[collider] = true
		return

	if collider is Node and (collider is breakable or collider.is_in_group("enemy")):
		for child in collider.find_children("*", "Area2D", true, false):
			if child is Area2D and child.is_in_group("hitbox"):
				hit_areas[child] = true
				return

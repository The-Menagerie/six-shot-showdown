class_name breakable extends RigidBody2D

@export var fade_duration := 0.2
@export var crush_min_downward_speed := 5.0
@export var player_push_impulse := 4.0
@export var player_bottom_push_impulse := 3.0

signal target_destroyed(target)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D2
@onready var hitbox_component: Area2D = $HitboxComponent
@onready var hitbox_collision: CollisionShape2D = $HitboxComponent/CollisionShape2D
@onready var break_audio: AudioStreamPlayer = $Break

var is_dying := false
var scene_reset_queued := false
var player_collision_enabled := true
var player_collision_body: PhysicsBody2D

func _ready() -> void:
	add_to_group("crush_object")
	add_to_group("breakable")
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)

func handle_death() -> void:
	if is_dying:
		return

	is_dying = true
	freeze = true
	_disable_collisions()
	_play_break_sound()
	target_destroyed.emit(self)

	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await fade_tween.finished
	queue_free()

func can_crush_enemy() -> bool:
	return not is_dying and linear_velocity.y > crush_min_downward_speed

func push_by_player(push_direction: Vector2) -> void:
	if push_direction == Vector2.ZERO or is_dying:
		return

	var shove := push_direction.normalized()
	shove.y *= 0.15
	apply_central_impulse(shove.normalized() * player_push_impulse)

func push_from_below_by_player(push_direction: Vector2) -> void:
	if is_dying:
		return

	var shove := push_direction
	if shove == Vector2.ZERO:
		shove = Vector2.LEFT

	shove = shove.normalized()
	shove.y = min(shove.y, -0.2)
	apply_central_impulse(shove.normalized() * player_bottom_push_impulse)

func _on_body_entered(body: Node) -> void:
	if scene_reset_queued:
		return
	if is_dying:
		return
	if not body.is_in_group("player"):
		return
	if linear_velocity.y <= crush_min_downward_speed:
		return
	if body.global_position.y <= global_position.y:
		return

	scene_reset_queued = true
	ScoreBus.player_died_to_crush()
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("reset_current_level"):
		game_manager.reset_current_level()

func _disable_collisions() -> void:
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)

	if is_instance_valid(hitbox_collision):
		hitbox_collision.set_deferred("disabled", true)

	if is_instance_valid(hitbox_component):
		hitbox_component.set_deferred("monitoring", false)
		hitbox_component.set_deferred("monitorable", false)

func set_player_collision_enabled(enabled: bool, player_body: PhysicsBody2D = null) -> void:
	player_collision_enabled = enabled
	if is_dying:
		return

	if player_body != null:
		player_collision_body = player_body

	if not is_instance_valid(player_collision_body):
		return

	if enabled:
		remove_collision_exception_with(player_collision_body)
	else:
		add_collision_exception_with(player_collision_body)

func _play_break_sound() -> void:
	if not is_instance_valid(break_audio) or break_audio.stream == null:
		return

	var owner := get_parent()
	if owner == null:
		return

	var detached_audio := AudioStreamPlayer.new()
	detached_audio.stream = break_audio.stream
	detached_audio.bus = break_audio.bus
	owner.add_child(detached_audio)
	_configure_audio_for_bullet_time(detached_audio)
	detached_audio.finished.connect(detached_audio.queue_free)
	detached_audio.play()

func _configure_audio_for_bullet_time(audio_player: AudioStreamPlayer) -> void:
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("configure_audio_player_for_bullet_time"):
		game_manager.configure_audio_player_for_bullet_time(audio_player)

func stabilize_after_swap(destination: Vector2, rotation_radians: float = 0.0) -> void:
	freeze = true
	sleeping = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = destination
	rotation = rotation_radians
	_finish_swap_stabilization()

func _finish_swap_stabilization() -> void:
	await get_tree().physics_frame
	global_position = global_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	await get_tree().physics_frame
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = true
	freeze = false

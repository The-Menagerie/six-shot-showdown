extends RigidBody2D

@export var attack_damage := 999.0
@export var attack_height_margin := 6.0
@export var bullet_knockback := 35.0
## Minimum downward speed in pixels/second to damage hitboxes or crush the player.
@export var crush_min_downward_speed := 20.0
@export var player_push_impulse := 4.0
@export var player_bottom_push_impulse := 3.0
@export var roll_min_speed := 3.0

@onready var attack_area: Area2D = $AttackArea
@onready var rolling_area: Area2D = $RollingArea

var scene_reset_queued := false
var swappable = true
var last_frame_ang_speed = 0.0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	attack_area.area_entered.connect(_on_attack_area_entered)
	body_entered.connect(_on_body_entered)
	rolling_area.area_entered.connect(_on_rolling_area_entered)

func _physics_process(_delta: float) -> void:
	_check_fall_attack_overlaps()
	_check_roll_attack_overlaps()
	
	if abs(angular_velocity) > 20:
		angular_velocity = (angular_velocity/abs(angular_velocity)) * 20
		print(angular_velocity)
	var current_vel = angular_velocity
	var abs_diff = abs(current_vel - last_frame_ang_speed)
	var a_dir = (current_vel - last_frame_ang_speed)/abs_diff
	if abs_diff > 3.0:
		if a_dir == 1:
			angular_velocity = last_frame_ang_speed + 3.0
		elif a_dir == -1:
			angular_velocity = last_frame_ang_speed - 3.0
func _on_attack_area_entered(area: Area2D) -> void:
	_try_fall_attack(area)

func _on_rolling_area_entered(area:Area2D) -> void:
	pass

func _check_fall_attack_overlaps() -> void:
	for area in attack_area.get_overlapping_areas():
		_try_fall_attack(area)
		
func _check_roll_attack_overlaps() -> void:
	for area in rolling_area.get_overlapping_areas():
		_try_roll_attack(area)

func _try_fall_attack(area: Area2D) -> void:
	if linear_velocity.y <= crush_min_downward_speed:
		return
	if not area.is_in_group("hitbox"):
		return
	if area.global_position.y <= global_position.y + attack_height_margin:
		return

	var attack := Attack.new()
	attack.attack_damage = attack_damage
	area.damage(attack)

func _try_roll_attack(area: Area2D) -> void:
	if not area.is_in_group("hitbox"):
			return
	if angular_velocity >= roll_min_speed:
		if area.global_position.x >= global_position.x:
			var attack := Attack.new()
			attack.attack_damage = attack_damage
			area.damage(attack)
	elif angular_velocity <= -1 * roll_min_speed:
		if area.global_position.x <= global_position.x:
			var attack := Attack.new()
			attack.attack_damage = attack_damage
			area.damage(attack)
	pass

func apply_bullet_knockback(hit_direction: Vector2) -> void:
	if hit_direction == Vector2.ZERO:
		return

	var knockback_direction := hit_direction.normalized()
	knockback_direction.y *= 0.2
	apply_central_impulse(knockback_direction.normalized() * bullet_knockback)

func push_by_player(push_direction: Vector2) -> void:
	if push_direction == Vector2.ZERO:
		return

	var shove := push_direction.normalized()
	shove.y *= 0.15
	apply_central_impulse(shove.normalized() * player_push_impulse)

func push_from_below_by_player(push_direction: Vector2) -> void:
	var shove := push_direction
	if shove == Vector2.ZERO:
		shove = Vector2.LEFT

	shove = shove.normalized()
	shove.y = min(shove.y, -0.2)
	apply_central_impulse(shove.normalized() * player_bottom_push_impulse)

func _on_body_entered(body: Node) -> void:
	if scene_reset_queued:
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

func stabilize_after_swap(destination: Vector2, rotation_radians: float = 0.0) -> void:
	freeze = true
	sleeping = true
	linear_velocity = Vector2.ZERO
	#angular_velocity = 0.0
	global_position = destination
	rotation = rotation_radians
	_finish_swap_stabilization()

func _finish_swap_stabilization() -> void:
	await get_tree().physics_frame
	global_position = global_position
	linear_velocity = Vector2.ZERO
	#angular_velocity = 0.0
	await get_tree().physics_frame
	linear_velocity = Vector2.ZERO
	#angular_velocity = 0.0
	sleeping = true
	freeze = false

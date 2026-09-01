extends RigidBody2D

@export var frozen_texture: Node

@export var attack_damage := 999.0
@export var attack_height_margin := 6.0
@export var attack_width_margin:= 6.0
@export var bullet_knockback := 35.0
@export var crush_min_downward_speed := 5.0
@export var player_push_impulse := 4.0
@export var player_bottom_push_impulse := 3.0


@onready var attack_area: Area2D = $AttackArea
@onready var left_crush_area: Area2D = $LeftCrushArea
@onready var right_crush_area: Area2D = $RightCrushArea


var scene_reset_queued := false
var rightward_crush = false
var leftward_crush = false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	attack_area.area_entered.connect(_on_attack_area_entered)
	body_entered.connect(_on_body_entered)
	left_crush_area.area_entered.connect(_on_left_crush_entered)
	right_crush_area.area_entered.connect(_on_right_crush_entered)

func _physics_process(_delta: float) -> void:
	angular_velocity = 0
	rotation = 0
	if rightward_crush == true and linear_velocity.x < 10.0:
		rightward_crush = false
	if leftward_crush == true and linear_velocity.x > -10.0:
		leftward_crush = false
	
	if rightward_crush:
		_check_right_crush_attack_overlaps()
	if leftward_crush:
		_check_left_crush_attack_overlaps()
	_check_fall_attack_overlaps()

func _on_attack_area_entered(area: Area2D) -> void:
	_try_fall_attack(area)

func _on_left_crush_entered(area: Area2D) -> void:
	if leftward_crush:
		_try_left_crush_attack(area)
	pass

func _on_right_crush_entered(area: Area2D) -> void:
	if rightward_crush:
		_try_right_crush_attack(area)
	pass

func _check_fall_attack_overlaps() -> void:
	for area in attack_area.get_overlapping_areas():
		_try_fall_attack(area)
		
func _check_left_crush_attack_overlaps() -> void:
	for area in left_crush_area.get_overlapping_areas():
		_try_left_crush_attack(area)
		
func _check_right_crush_attack_overlaps() -> void:
	for area in right_crush_area.get_overlapping_areas():
		_try_right_crush_attack(area)

func _try_fall_attack(area: Area2D) -> void:
	if linear_velocity.y <= 0.0:
		return
	if not area.is_in_group("hitbox"):
		return
	if area.global_position.y <= global_position.y + attack_height_margin:
		return

	var attack := Attack.new()
	attack.attack_damage = attack_damage
	area.damage(attack)

func _try_left_crush_attack(area:Area2D) -> void:
	if linear_velocity.x >= 0.0:
		return
	if not area.is_in_group("hitbox"):
		return
	if area.global_position.x >= global_position.x - attack_width_margin:
		return

	var attack := Attack.new()
	attack.attack_damage = attack_damage
	area.damage(attack)

func _try_right_crush_attack(area:Area2D) -> void:
	if linear_velocity.x <= 0.0:
		return
	if not area.is_in_group("hitbox"):
		return
	if area.global_position.x <= global_position.x + attack_width_margin:
		return

	var attack := Attack.new()
	attack.attack_damage = attack_damage
	area.damage(attack)

#func apply_bullet_knockback(hit_direction: Vector2) -> void:
	#if hit_direction == Vector2.ZERO:
		#return
#
	#var knockback_direction := hit_direction.normalized()
	#knockback_direction.y *= 0.2
	#apply_central_impulse(knockback_direction.normalized() * bullet_knockback)

func ice_cube_rubber_knockback(hit_direction: Vector2) -> void:
	if hit_direction == Vector2.ZERO:
		return

	var knockback_direction := hit_direction.normalized()
	knockback_direction.y *= 0.2
	apply_central_impulse(knockback_direction.normalized() * bullet_knockback)
	if hit_direction.x > 0.0:
		rightward_crush = true
	elif hit_direction.x < 0.0:
		leftward_crush = true
		

func push_by_player(push_direction: Vector2) -> void:
	if push_direction == Vector2.ZERO:
		return

	var shove := push_direction.normalized()
	shove.y *= 0.15
	apply_central_impulse(shove.normalized() * player_push_impulse)

#func push_from_below_by_player(push_direction: Vector2) -> void:
	#var shove := push_direction
	#if shove == Vector2.ZERO:
		#shove = Vector2.LEFT
#
	#shove = shove.normalized()
	#shove.y = min(shove.y, -0.2)
	#apply_central_impulse(shove.normalized() * player_bottom_push_impulse)

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

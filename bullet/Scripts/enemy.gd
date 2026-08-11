extends CharacterBody2D

@export var gravity : float = 900.0
@export var patrol_speed : float = 40.0
@export var patrol_radius : float = 48.0
@export var idle_duration : float = 1.2
@export var walk_duration : float = 2.4
@export var idle_duration_variance : float = 0.3
@export var walk_duration_variance : float = 0.5
@export var starting_direction : float = 1.0
@export var ledge_check_forward_distance : float = 10.0
@export var ledge_check_depth : float = 24.0
@export var hazard_check_height : float = 6.0
@export var combat_enter_distance : float = 75.0
@export var combat_exit_distance : float = 100.0
@export var alert_time : float = 0.35
@export var fire_interval : float = 1.0
@export var knockback_drag: float = 0.2
@export var knockback_end_velocity: float = 20.0

signal target_destroyed(target)

const DEATH_SOUND = preload("res://Assets/SoundEffects/EnemyDeath.wav")
const DEATH_ANIMATION_DURATION := 0.4

var is_dying := false
var knockedback := false
var facing_direction : float = 1.0
var patrol_direction : float = 1.0
var is_patrolling := false
var phase_timer : float = 0.0
var home_position : Vector2 = Vector2.ZERO
var is_in_combat := false
var fire_timer : float = 0.0
var has_played_alert := false
var rng := RandomNumberGenerator.new()
var carried_drop: Node2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine = animation_tree["parameters/playback"]
@onready var movement_collision: CollisionShape2D = $MovementCollision
@onready var hitbox_component: Area2D = $HitboxComponent
@onready var hitbox_collision: CollisionShape2D = $HitboxComponent/CollisionShape2D2
@onready var crush_detector: Area2D = $CrushDetector
@onready var enemy_shotgun: Node2D = $EnemyShotgun
@onready var player_target: Node2D = _find_player()
@onready var alert_audio: AudioStreamPlayer = $Alert
@onready var hit_timer: Timer = $HitTimer

func _ready():
	add_to_group("enemy")
	rng.randomize()
	if is_instance_valid(animation_tree):
		animation_tree.active = true
	carried_drop = _find_carried_drop()
	if is_instance_valid(carried_drop) and carried_drop.has_method("set_carried_state"):
		carried_drop.set_carried_state(true)
	home_position = global_position
	patrol_direction = starting_direction if starting_direction != 0.0 else 1.0
	facing_direction = patrol_direction
	fire_timer = fire_interval
	_start_idle_phase()
	_update_animation_parameters()
	_pick_animation_state()
	if is_instance_valid(hit_timer):
		hit_timer.timeout.connect(_on_hit_timer_timeout)

func set_home_position_to_current() -> void:
	home_position = global_position
	if patrol_direction == 0.0:
		patrol_direction = starting_direction if starting_direction != 0.0 else 1.0
	facing_direction = patrol_direction

func _physics_process(delta):
	if is_dying:
		return
	if not knockedback:
		_update_combat_state()
		if not is_in_combat:
			_update_patrol(delta)
		else:
			_update_combat_fire(delta)
		
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0.0

		if is_in_combat:
			velocity.x = 0.0
		else:
			velocity.x = patrol_direction * patrol_speed if is_patrolling else 0.0
	
	move_and_slide()
	_check_crush_overlaps()
	
	if knockedback:
		if not is_on_floor():
			velocity.y += gravity/5 * delta
		else:
			velocity.y = 0.0
		if velocity.x > 0:
			velocity.x = velocity.x * (1-knockback_drag)
		if velocity.length() < 20:
			knockedback = false
			
	if not is_in_combat and is_on_wall() and is_patrolling:
		patrol_direction = -sign(velocity.x) if velocity.x != 0.0 else -patrol_direction
		facing_direction = patrol_direction
	elif not is_in_combat and is_patrolling and is_on_floor() and (not _has_floor_ahead() or _has_hazard_ahead()):
		patrol_direction *= -1.0
		facing_direction = patrol_direction

	_update_animation_parameters()
	_pick_animation_state()

func handle_death():
	if is_dying:
		return

	is_dying = true
	var death_velocity = velocity
	_disable_collisions()
	velocity = Vector2.ZERO
	_play_death_animation()
	_play_death_sound()
	_drop_shotgun(death_velocity)
	_drop_carried_item()
	await get_tree().create_timer(DEATH_ANIMATION_DURATION).timeout
	target_destroyed.emit(self)
	queue_free()

func _play_death_sound():
	var owner = get_parent()
	if owner == null:
		return

	var death_audio := AudioStreamPlayer.new()
	death_audio.stream = DEATH_SOUND
	death_audio.bus = "sfx"
	owner.add_child(death_audio)
	_configure_audio_for_bullet_time(death_audio)
	death_audio.finished.connect(death_audio.queue_free)
	death_audio.play()

func _update_animation_parameters():
	if velocity.x != 0.0:
		facing_direction = sign(velocity.x)

	if is_instance_valid(animation_tree):
		animation_tree.set("parameters/Idle/blend_position", facing_direction)
		animation_tree.set("parameters/Walk/blend_position", facing_direction)
		animation_tree.set("parameters/Jump/blend_position", facing_direction)
		animation_tree.set("parameters/Death/blend_position", facing_direction)

	if is_instance_valid(enemy_shotgun):
		_update_shotgun_facing()

func _pick_animation_state():
	if state_machine == null:
		return

	if not is_on_floor():
		state_machine.travel("Jump")
	elif abs(velocity.x) > 0.1:
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")

func _play_death_animation():
	if state_machine == null:
		return

	_update_animation_parameters()
	state_machine.travel("Death")

func _disable_collisions():
	if is_instance_valid(movement_collision):
		movement_collision.set_deferred("disabled", true)

	if is_instance_valid(hitbox_collision):
		hitbox_collision.set_deferred("disabled", true)

	if is_instance_valid(hitbox_component):
		hitbox_component.set_deferred("monitoring", false)
		hitbox_component.set_deferred("monitorable", false)

func _update_patrol(delta):
	phase_timer -= delta

	if is_patrolling:
		_update_patrol_direction(delta)

	if phase_timer > 0.0:
		return

	if is_patrolling:
		_start_idle_phase()
	else:
		_start_walk_phase()

func _start_idle_phase():
	is_patrolling = false
	phase_timer = _get_phase_duration(idle_duration, idle_duration_variance)

func _start_walk_phase():
	is_patrolling = true
	phase_timer = _get_phase_duration(walk_duration, walk_duration_variance)

func _get_phase_duration(base_duration: float, variance: float) -> float:
	return max(0.1, base_duration + rng.randf_range(-variance, variance))

func _update_patrol_direction(delta):
	var distance_from_home = global_position.x - home_position.x
	var boundary_threshold = max(2.0, patrol_speed * delta)

	if distance_from_home >= patrol_radius - boundary_threshold:
		patrol_direction = -1.0
	elif distance_from_home <= -patrol_radius + boundary_threshold:
		patrol_direction = 1.0
	elif abs(distance_from_home) < boundary_threshold and patrol_direction == 0.0:
		patrol_direction = starting_direction if starting_direction != 0.0 else 1.0

	facing_direction = patrol_direction

func _has_floor_ahead() -> bool:
	var query := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(patrol_direction * ledge_check_forward_distance, 0.0),
		global_position + Vector2(patrol_direction * ledge_check_forward_distance, ledge_check_depth)
	)
	query.exclude = [self]
	var result = get_world_2d().direct_space_state.intersect_ray(query)
	return not result.is_empty()

func _has_hazard_ahead() -> bool:
	var start := global_position + Vector2(patrol_direction * ledge_check_forward_distance, -hazard_check_height)
	var finish := global_position + Vector2(patrol_direction * ledge_check_forward_distance, hazard_check_height)
	var query := PhysicsRayQueryParameters2D.create(start, finish)
	query.exclude = [self]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false

	var collider := result.collider as Node
	if collider == null:
		return false

	if collider.is_in_group("enemy_hazard"):
		return true

	var parent := collider.get_parent()
	return parent != null and parent.is_in_group("enemy_hazard")

func _drop_shotgun(initial_velocity: Vector2):
	if not is_instance_valid(enemy_shotgun):
		return

	var parent = get_parent()
	if parent == null:
		return

	var shotgun_global_position = enemy_shotgun.global_position
	var shotgun_global_scale = enemy_shotgun.global_scale
	remove_child(enemy_shotgun)
	parent.add_child(enemy_shotgun)
	enemy_shotgun.global_position = shotgun_global_position
	enemy_shotgun.global_scale = shotgun_global_scale

	if enemy_shotgun.has_method("drop"):
		enemy_shotgun.drop(Vector2(initial_velocity.x * 0.35, initial_velocity.y))

func _drop_carried_item() -> void:
	if not is_instance_valid(carried_drop):
		return

	var parent = get_parent()
	if parent == null:
		return

	var drop_node: Node2D = carried_drop
	var drop_global_position: Vector2 = carried_drop.global_position
	call_deferred("_finish_drop_carried_item", drop_node, parent, drop_global_position)

func _finish_drop_carried_item(drop_node: Node2D, parent: Node, drop_global_position: Vector2) -> void:
	if not is_instance_valid(drop_node):
		return
	if parent == null or not is_instance_valid(parent):
		return

	if drop_node.get_parent() == self:
		remove_child(drop_node)
	parent.add_child(drop_node)
	drop_node.global_position = drop_global_position

	if drop_node.has_method("drop_from_carrier"):
		drop_node.drop_from_carrier()

func _update_combat_state():
	var was_in_combat = is_in_combat

	if not is_instance_valid(player_target):
		player_target = _find_player()
		if not is_instance_valid(player_target):
			is_in_combat = false
			return

	var player_distance = global_position.distance_to(player_target.global_position)
	var has_line_of_sight = _has_line_of_sight_to_player()
	if is_in_combat:
		is_in_combat = player_distance <= combat_exit_distance and has_line_of_sight
	else:
		is_in_combat = player_distance <= combat_enter_distance and has_line_of_sight

	if is_in_combat and not was_in_combat:
		if is_instance_valid(alert_audio) and not has_played_alert:
			alert_audio.play()
			has_played_alert = true
		fire_timer = alert_time
	elif not is_in_combat and was_in_combat:
		has_played_alert = false
		fire_timer = fire_interval

func _update_shotgun_facing():
	if is_in_combat and is_instance_valid(player_target):
		var aim_vector = player_target.global_position - enemy_shotgun.global_position
		if aim_vector == Vector2.ZERO:
			return

		if aim_vector.x < 0.0:
			enemy_shotgun.scale.x = -1.0
			enemy_shotgun.rotation = aim_vector.angle() - PI
			facing_direction = -1.0
		else:
			enemy_shotgun.scale.x = 1.0
			enemy_shotgun.rotation = aim_vector.angle()
			facing_direction = 1.0
		return

	enemy_shotgun.rotation = 0.0
	enemy_shotgun.scale.x = -1.0 if facing_direction < 0.0 else 1.0

func _find_player() -> Node2D:
	var parent = get_parent()
	if parent != null:
		var parent_player = parent.get_node_or_null("Player")
		if parent_player is Node2D:
			return parent_player

	var scene_player = get_tree().root.find_child("Player", true, false)
	if scene_player is Node2D:
		return scene_player

	return null

func _find_carried_drop() -> Node2D:
	for child in find_children("*", "Node2D", true, false):
		if child == self:
			continue
		if child.has_method("set_carried_state") and child.has_method("drop_from_carrier"):
			return child

	return null

func _has_line_of_sight_to_player() -> bool:
	if not is_instance_valid(player_target):
		return false
 
	var query := PhysicsRayQueryParameters2D.create(global_position, player_target.global_position)
	query.exclude = _build_line_of_sight_exclusions()
	query.collision_mask = 1
	var result = get_world_2d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return true

	var collider = result.collider as Node
	if collider == null:
		return false

	if collider.is_in_group("player"):
		return true

	var parent = collider.get_parent()
	return parent != null and parent.is_in_group("player")

func _build_line_of_sight_exclusions() -> Array:
	var exclusions: Array = [self]

	if is_instance_valid(enemy_shotgun):
		exclusions.append(enemy_shotgun)

	for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
		if projectile != null:
			exclusions.append(projectile)

	return exclusions

func _update_combat_fire(delta):
	if not is_instance_valid(player_target) or not is_instance_valid(enemy_shotgun):
		return

	fire_timer -= delta
	if fire_timer > 0.0:
		return

	var aim_vector = player_target.global_position - enemy_shotgun.global_position
	if aim_vector == Vector2.ZERO:
		return

	var projectile_parent = get_parent()
	if projectile_parent == null:
		return

	if enemy_shotgun.has_method("fire"):
		enemy_shotgun.fire(aim_vector, projectile_parent)

	fire_timer = fire_interval

func _check_crush_overlaps() -> void:
	if is_dying or not is_instance_valid(crush_detector):
		return

	for body in crush_detector.get_overlapping_bodies():
		if body is Node and body.is_in_group("crush_object") and body.has_method("can_crush_enemy") and body.can_crush_enemy():
			handle_death()
			return

func _on_hit_timer_timeout() -> void:
	knockedback = false

func _configure_audio_for_bullet_time(audio_player: AudioStreamPlayer) -> void:
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("configure_audio_player_for_bullet_time"):
		game_manager.configure_audio_player_for_bullet_time(audio_player)

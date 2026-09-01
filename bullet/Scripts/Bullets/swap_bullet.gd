extends CharacterBody2D

@export var speed : float = 500.0
@export var damage : float = 10.0
@export var max_bounces : int = 3
@export var recoil_multiplier: float = 1.0
@export var rope_pass_through_distance : float = 6.0
@export var post_hit_cleanup_delay : float = 0.05

var direction : Vector2 = Vector2.RIGHT
var area_2d: Area2D
var bounce_count : int = 0
var shooter: Node
var is_armed := false
var has_registered_hit := false
var swap_origin_metrics: Dictionary = {}
var has_swap_origin := false

@onready var ricochet_audio: AudioStreamPlayer = $RicochetAudio
@onready var movement_collision: CollisionShape2D = $MovementCollision

func _ready():
	area_2d = $Area2D
	area_2d.area_entered.connect(_on_area_entered)
	area_2d.add_to_group("bullet")
	area_2d.monitoring = false
	area_2d.monitorable = false
	if is_instance_valid(movement_collision):
		movement_collision.disabled = true

func _physics_process(delta):
	if not is_armed or has_registered_hit:
		return

	velocity = direction * speed
	var next_position: Vector2 = global_position + velocity * delta
	if _try_cut_rope_between(global_position, next_position):
		global_position = next_position
		rotation = direction.angle()
		return

	var collision = move_and_collide(velocity * delta)
	if collision:
		if _try_damage_collider(collision.get_collider()):
			_finish_after_successful_hit()
			return
		if bounce_count >= max_bounces:
			ricochet_audio.play()
			queue_free()
			return
		if not _confirm_bounce(collision):
			queue_free()
			return
		bounce_count += 1
		direction = direction.bounce(collision.get_normal()).normalized()
		rotation = direction.angle()
		ricochet_audio.play()


func _on_area_entered(area: Area2D):
	if has_registered_hit:
		return

	if _try_damage_hitbox(area):
		_finish_after_successful_hit()

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
	rotation = direction.angle()
	#print("Bullet velocity set to: "+str(direction))

func capture_swap_origin(source_node: Node2D) -> void:
	if not is_instance_valid(source_node):
		return

	swap_origin_metrics = _get_swap_metrics(source_node)
	has_swap_origin = true

func arm() -> void:
	call_deferred("_finish_arming")

func _finish_arming() -> void:
	if not is_inside_tree():
		return

	if is_instance_valid(movement_collision):
		movement_collision.set_deferred("disabled", false)
	if is_instance_valid(area_2d):
		area_2d.set_deferred("monitoring", true)
		area_2d.set_deferred("monitorable", true)
	is_armed = true

func _try_damage_collider(collider: Node) -> bool:
	if has_registered_hit:
		return false

	if collider is Area2D:
		return _try_damage_hitbox(collider)

	for child in collider.get_children():
		if child is Area2D and _try_damage_hitbox(child):
			return true

	return false

func _try_damage_hitbox(area: Area2D) -> bool:
	if has_registered_hit:
		return false

	if not area.is_in_group("hitbox"):
		return false
	
	var swap_target = area.get_parent()
	if not (swap_target is Node):
		return false

	var is_valid_swap_target := swap_target.is_in_group("enemy") or swap_target is breakable
	if not is_valid_swap_target:
		return false

	if not (swap_target is Node2D) or not (shooter is Node2D):
		return false

	var shooter_node := shooter as Node2D
	var target_node := swap_target as Node2D
	var shooter_metrics := _get_swap_metrics(shooter_node)
	var target_metrics := _get_swap_metrics(target_node)
	var shooter_destination := Vector2(
		target_metrics.collision_center.x - shooter_metrics.center_offset.x,
		target_metrics.bottom_y - shooter_metrics.bottom_offset
	)
	var target_destination := Vector2(
		shooter_metrics.collision_center.x - target_metrics.center_offset.x,
		shooter_metrics.bottom_y - target_metrics.bottom_offset
	)
	if target_node is RigidBody2D:
		target_destination = _resolve_non_overlapping_swap_destination(target_node, target_destination, [shooter_node, target_node])

	if target_node is RigidBody2D:
		var rigid_target := target_node as RigidBody2D
		rigid_target.freeze = true
		rigid_target.sleeping = true
		rigid_target.linear_velocity = Vector2.ZERO
		rigid_target.angular_velocity = 0.0

	if target_node is RigidBody2D:
		var rigid_target := target_node as RigidBody2D
		if rigid_target.has_method("stabilize_after_swap"):
			rigid_target.stabilize_after_swap(target_destination, 0.0)
		else:
			rigid_target.global_position = target_destination
			rigid_target.rotation = 0.0
			rigid_target.linear_velocity = Vector2.ZERO
			rigid_target.angular_velocity = 0.0
			rigid_target.sleeping = true
			rigid_target.set_deferred("freeze", false)
	else:
		target_node.global_position = target_destination
		_reset_swap_motion(target_node)

	if target_node.has_method("set_home_position_to_current"):
		target_node.set_home_position_to_current()

	shooter_node.global_position = shooter_destination
	_reset_swap_motion(shooter_node)
	
	var attack = Attack.new()
	attack.attack_damage = damage
	area.damage(attack)
	return true

func _get_swap_metrics(node: Node2D) -> Dictionary:
	var collision_shape := _find_primary_collision_shape(node)
	if collision_shape == null:
		return {
			"collision_center": node.global_position,
			"center_offset": Vector2.ZERO,
			"bottom_offset": 0.0,
			"bottom_y": node.global_position.y,
		}

	var collision_center := collision_shape.global_position
	var bottom_y := _get_collision_bottom_y(collision_shape)

	return {
		"collision_center": collision_center,
		"center_offset": collision_center - node.global_position,
		"bottom_offset": bottom_y - node.global_position.y,
		"bottom_y": bottom_y,
	}

func _find_primary_collision_shape(node: Node) -> CollisionShape2D:
	for child in node.find_children("*", "CollisionShape2D", true, false):
		if child is not CollisionShape2D:
			continue
		if child.get_parent() is Area2D:
			continue
		return child as CollisionShape2D

	return null

func _get_collision_bottom_y(collision_shape: CollisionShape2D) -> float:
	if collision_shape.shape is RectangleShape2D:
		var rectangle := collision_shape.shape as RectangleShape2D
		var half_size := rectangle.size * 0.5
		var corners := [
			Vector2(-half_size.x, -half_size.y),
			Vector2(half_size.x, -half_size.y),
			Vector2(half_size.x, half_size.y),
			Vector2(-half_size.x, half_size.y),
		]
		var transform := collision_shape.global_transform
		var bottom_y := -INF
		for corner in corners:
			bottom_y = max(bottom_y, (transform * corner).y)
		return bottom_y

	return collision_shape.global_position.y

func _reset_swap_motion(node: Node2D) -> void:
	if node is CharacterBody2D:
		var character := node as CharacterBody2D
		character.velocity = Vector2.ZERO

	if "recoil_velocity" in node:
		node.recoil_velocity = Vector2.ZERO

func _resolve_non_overlapping_swap_destination(
	node: Node2D,
	desired_position: Vector2,
	exclusions: Array
) -> Vector2:
	var collision_shape := _find_primary_collision_shape(node)
	if collision_shape == null or collision_shape.shape == null:
		return desired_position

	if _is_swap_destination_clear(node, collision_shape, desired_position, exclusions):
		return desired_position

	var search_offsets := [
		Vector2(8, 0), Vector2(-8, 0), Vector2(0, -8), Vector2(0, 8),
		Vector2(16, 0), Vector2(-16, 0), Vector2(8, -8), Vector2(-8, -8),
		Vector2(8, 8), Vector2(-8, 8), Vector2(0, -16), Vector2(0, 16),
		Vector2(24, 0), Vector2(-24, 0), Vector2(16, -8), Vector2(-16, -8),
		Vector2(16, 8), Vector2(-16, 8), Vector2(24, -8), Vector2(-24, -8),
		Vector2(24, 8), Vector2(-24, 8), Vector2(32, 0), Vector2(-32, 0),
		Vector2(0, -24), Vector2(0, 24), Vector2(32, -8), Vector2(-32, -8),
		Vector2(32, 8), Vector2(-32, 8), Vector2(16, -16), Vector2(-16, -16),
		Vector2(24, -16), Vector2(-24, -16), Vector2(32, -16), Vector2(-32, -16),
	]

	for offset in search_offsets:
		var candidate: Vector2 = desired_position + offset
		if _is_swap_destination_clear(node, collision_shape, candidate, exclusions):
			return candidate

	return desired_position

func _is_swap_destination_clear(
	node: Node2D,
	collision_shape: CollisionShape2D,
	candidate_position: Vector2,
	exclusions: Array
) -> bool:
	var center_offset := collision_shape.global_position - node.global_position
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = Transform2D(0.0, candidate_position + center_offset)
	query.exclude = exclusions
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var results := get_world_2d().direct_space_state.intersect_shape(query, 8)
	return results.is_empty()

func _finish_after_successful_hit() -> void:
	if has_registered_hit:
		return

	has_registered_hit = true
	is_armed = false
	velocity = Vector2.ZERO
	if is_instance_valid(movement_collision):
		movement_collision.set_deferred("disabled", true)
	if is_instance_valid(area_2d):
		area_2d.set_deferred("monitoring", false)
		area_2d.set_deferred("monitorable", false)

	var timer := get_tree().create_timer(post_hit_cleanup_delay)
	timer.timeout.connect(queue_free)


func _confirm_bounce(collision: KinematicCollision2D) -> bool:
	var collider = collision.get_collider()
	var collision_pos = collision.get_position()
	if collider is TileMapLayer:
		var collision_cell_pos = collider.local_to_map(collision_pos)
		var data = collider.get_cell_tile_data(collision_cell_pos)
		if data == null:
			var near_cells = collider.get_surrounding_cells(collision_cell_pos)
			var nearby_bounce_count = 0
			for i in near_cells:
				data = collider.get_cell_tile_data(i)
				if data != null:
					if data.get_custom_data("bullets_bounce"):
						nearby_bounce_count += 1
					else:
						nearby_bounce_count -= 1
			if nearby_bounce_count < 0:
				#print(nearby_bounce_count)
				return false
			else:
				#print(nearby_bounce_count)
				return true
		if data != null:
			if not data.get_custom_data("bullets_bounce"):
				return false
	return true

func _try_cut_rope_between(segment_start: Vector2, segment_end: Vector2) -> bool:
	var ropes: Array[Node] = get_tree().get_nodes_in_group("rope")
	for rope: Node in ropes:
		if rope.has_method("cut_along_segment") and rope.cut_along_segment(segment_start, segment_end, rope_pass_through_distance):
			return true

	return false

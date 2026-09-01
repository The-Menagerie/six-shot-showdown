class_name Bullet
extends CharacterBody2D

@export var speed: float = 500.0
@export var damage: float = 10.0
@export var max_bounces: int = 3
@export var recoil_multiplier: float = 1.0
@export var rope_pass_through_distance: float = 6.0

var direction: Vector2 = Vector2.RIGHT
var area_2d: Area2D
var bounce_count: int = 0
var shooter: Node

@onready var ricochet_audio: AudioStreamPlayer = $RicochetAudio

func _ready() -> void:
	area_2d = $Area2D
	area_2d.area_entered.connect(_on_area_entered)
	area_2d.add_to_group("bullet")
	_after_ready()

func _after_ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not _can_process_bullet():
		return

	velocity = direction * speed
	var next_position: Vector2 = global_position + velocity * delta
	_before_move(global_position, next_position)
	if _should_cut_rope_between(global_position, next_position) and _try_cut_rope_between(global_position, next_position):
		global_position = next_position
		rotation = direction.angle()
		return

	var collision := move_and_collide(velocity * delta)
	if collision:
		_handle_collision(collision)

func _can_process_bullet() -> bool:
	return true

func _before_move(_segment_start: Vector2, _segment_end: Vector2) -> void:
	_try_ignite_fuse_between(_segment_start, _segment_end)

func _should_cut_rope_between(_segment_start: Vector2, _segment_end: Vector2) -> bool:
	return true

func _handle_collision(collision: KinematicCollision2D) -> void:
	if _try_damage_collider(collision.get_collider()):
		_on_successful_damage()
		return
	if bounce_count >= max_bounces:
		_play_ricochet()
		queue_free()
		return
	if not _confirm_bounce(collision):
		queue_free()
		return
	_on_confirmed_bounce(collision)

func _on_confirmed_bounce(collision: KinematicCollision2D) -> void:
	bounce_count += 1
	direction = direction.bounce(collision.get_normal()).normalized()
	rotation = direction.angle()
	_play_ricochet()

func _on_area_entered(area: Area2D) -> void:
	if _try_damage_hitbox(area):
		_on_successful_damage()

func _on_successful_damage() -> void:
	queue_free()

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	rotation = direction.angle()

func _try_damage_collider(collider: Node) -> bool:
	if collider is Area2D:
		return _try_damage_hitbox(collider)

	if _should_apply_bullet_knockback(collider):
		collider.apply_bullet_knockback(direction)

	for child in collider.get_children():
		if child is Area2D and _try_damage_hitbox(child):
			return true

	return false

func _should_apply_bullet_knockback(collider: Node) -> bool:
	return collider.has_method("apply_bullet_knockback")

func _try_damage_hitbox(area: Area2D) -> bool:
	if not area.is_in_group("hitbox"):
		return false

	var attack := Attack.new()
	attack.attack_damage = damage
	area.damage(attack)
	return true

func _confirm_bounce(collision: KinematicCollision2D) -> bool:
	var collider := collision.get_collider()
	var collision_pos := collision.get_position()
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
			return nearby_bounce_count >= 0
		if data != null and not data.get_custom_data("bullets_bounce"):
			return false
	return true

func _try_cut_rope_between(segment_start: Vector2, segment_end: Vector2) -> bool:
	var ropes: Array[Node] = get_tree().get_nodes_in_group("rope")
	for rope: Node in ropes:
		if rope.has_method("cut_along_segment") and rope.cut_along_segment(segment_start, segment_end, rope_pass_through_distance):
			return true

	return false

func _try_ignite_fuse_between(segment_start: Vector2, segment_end: Vector2) -> void:
	var fuses: Array[Node] = get_tree().get_nodes_in_group("fuse")
	for fuse: Node in fuses:
		if fuse.has_method("ignite_along_segment"):
			fuse.ignite_along_segment(segment_start, segment_end, rope_pass_through_distance)

func _play_ricochet() -> void:
	if is_instance_valid(ricochet_audio):
		ricochet_audio.play()

extends "res://Scripts/Bullets/bullet.gd"

var has_key := true
var single_use := true

func _after_ready() -> void:
	add_to_group("key_bullet")
	area_2d.add_to_group("key_bullet")

func _handle_collision(collision: KinematicCollision2D) -> void:
	if _try_unlock_lock_block(collision):
		return

	super._handle_collision(collision)

func _should_cut_rope_between(segment_start: Vector2, segment_end: Vector2) -> bool:
	# Rope cutting can skip the solid movement check. Preview the same swept
	# movement first so a lock shields rope behind it and consumes/bounces the shot.
	var collision := move_and_collide(segment_end - segment_start, true)
	return collision == null or _get_lock_handler(collision) == null

func _try_unlock_lock_block(collision: KinematicCollision2D) -> bool:
	var handler := _get_lock_handler(collision)
	if handler == null:
		return false
	return bool(handler.call("try_unlock_key_bullet", self, collision.get_normal()))

func _get_lock_handler(collision: KinematicCollision2D) -> Node:
	var collider := collision.get_collider()
	if collider == null:
		return null

	var handler := collider
	if not handler.has_method("try_unlock_key_bullet"):
		handler = collider.get_parent()
	if handler == null or not handler.has_method("try_unlock_key_bullet"):
		return null
	return handler

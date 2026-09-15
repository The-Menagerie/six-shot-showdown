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

func _try_unlock_lock_block(collision: KinematicCollision2D) -> bool:
	var collider := collision.get_collider()
	if collider == null:
		return false

	var handler := collider
	if not handler.has_method("try_unlock_key_bullet"):
		handler = collider.get_parent()
	if handler == null or not handler.has_method("try_unlock_key_bullet"):
		return false

	return bool(handler.call("try_unlock_key_bullet", self, collision.get_normal()))

extends "res://Scripts/Bullets/bullet.gd"

@export var knock_back: float = 15.0

func _handle_collision(collision: KinematicCollision2D) -> void:
	if _try_damage_collider(collision.get_collider()):
		pass
	if bounce_count >= max_bounces:
		_play_ricochet()
		queue_free()
		return
	if not _confirm_bounce(collision):
		queue_free()
		return
	_on_confirmed_bounce(collision)

func _on_successful_damage() -> void:
	pass

func _should_apply_bullet_knockback(_collider: Node) -> bool:
	return false

func _try_damage_hitbox(area: Area2D) -> bool:
	if not area.is_in_group("hitbox"):
		return false

	var knock_back_target = area.get_parent()
	if knock_back_target is CharacterBody2D:
		var kb_timer = knock_back_target.find_child("HitTimer")
		if kb_timer.is_stopped():
			knock_back_target.velocity.x += direction.x * knock_back
			knock_back_target.velocity.y += direction.y * knock_back
			knock_back_target.knockedback = true
			kb_timer.start()

	var attack := Attack.new()
	attack.attack_damage = damage
	area.damage(attack)
	return true

func _confirm_bounce(collision: KinematicCollision2D) -> bool:
	var can_bounce := super._confirm_bounce(collision)
	if can_bounce:
		var collider := collision.get_collider()
		if collider.has_method("ice_cube_rubber_knockback"):
			collider.ice_cube_rubber_knockback(direction)
	return can_bounce

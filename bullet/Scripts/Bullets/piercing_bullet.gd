extends "res://Scripts/Bullets/bullet.gd"

func _on_successful_damage() -> void:
	pass

func _should_apply_bullet_knockback(_collider: Node) -> bool:
	return false

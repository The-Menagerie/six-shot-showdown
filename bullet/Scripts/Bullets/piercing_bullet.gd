extends "res://Scripts/Bullets/bullet.gd"

func _create_attack() -> Attack:
	var attack := super._create_attack()
	attack.is_piercing = true
	return attack

func _on_successful_damage() -> void:
	pass

func _should_apply_bullet_knockback(_collider: Node) -> bool:
	return false

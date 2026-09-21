extends "res://Scripts/Bullets/bullet.gd"

func _after_ready() -> void:
	recoil_multiplier = 2.0
	_play_detached_sound($Bird)

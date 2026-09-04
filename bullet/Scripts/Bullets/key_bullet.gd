extends "res://Scripts/Bullets/bullet.gd"

var has_key := true
var single_use := true

func _after_ready() -> void:
	add_to_group("key_bullet")
	area_2d.add_to_group("key_bullet")

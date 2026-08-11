extends Node

signal fire_player_bullet(Bullet: PackedScene)
signal force_rescale(scale: float)
signal out_of_ammo_changed(is_out_of_ammo: bool)

var current_chamber_scale: float = 3.0

func change_chamber_scale(new_scale: float) -> void:
	current_chamber_scale = new_scale
	force_rescale.emit(current_chamber_scale)

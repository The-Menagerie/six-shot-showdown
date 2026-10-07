extends Node2D

# A visual souvenir of the enemy, with no AI, collisions, or audio.
func play(source: Sprite2D, destination: Vector2, tiny_scale: float, fall_speed: float, spin_speed: float, lifetime: float, effect_z_index: int = -10, horizontal_drift_speed: float = 0.0) -> void:
	# Move in world coordinates, independently of the source and its parent.
	top_level = true
	global_transform = source.global_transform
	scale *= tiny_scale
	var sprite := source.duplicate() as Sprite2D
	add_child(sprite)
	sprite.transform = Transform2D.IDENTITY
	sprite.z_index = 0
	sprite.z_as_relative = true
	z_index = effect_z_index
	z_as_relative = false
	var starting_rotation := rotation
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", destination, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", starting_rotation + deg_to_rad(spin_speed) * 0.45, 0.45)
	tween.chain().tween_property(self, "global_position", destination + Vector2(horizontal_drift_speed, fall_speed) * lifetime, lifetime)
	tween.parallel().tween_property(self, "rotation", starting_rotation + deg_to_rad(spin_speed) * (lifetime + 0.45), lifetime)
	tween.parallel().tween_property(self, "modulate:a", 0.0, minf(1.0, lifetime)).set_delay(maxf(0.0, lifetime - 1.0))
	tween.chain().tween_callback(queue_free)

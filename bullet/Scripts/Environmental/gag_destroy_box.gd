extends Area2D

@export var distance_offset := Vector2.ZERO
@export_range(-4096, 4096, 1) var enemy_z_index := -10
@export_range(0.05, 0.5, 0.01) var tiny_scale := 0.18
@export_range(0.0, 40.0, 0.5) var fall_speed := 8.0
@export_range(-100.0, 100.0, 0.5) var horizontal_drift_speed := 0.0
@export_range(-180.0, 180.0, 1.0) var spin_degrees_per_second := 45.0
@export_range(1.0, 30.0, 0.5) var fall_duration := 12.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemy") or not body.has_method("handle_gag_death"):
		return
	var destination := body.global_position + distance_offset
	# The trigger position and configured offset fully determine the world path.
	body.handle_gag_death(destination, tiny_scale, fall_speed, spin_degrees_per_second, fall_duration, enemy_z_index, horizontal_drift_speed)

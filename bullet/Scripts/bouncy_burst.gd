extends Node2D

@export var frame_count := 16
@export var animation_duration := 0.25

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if not is_instance_valid(sprite):
		queue_free()
		return

	sprite.frame = 0
	var tween := create_tween()
	tween.tween_property(sprite, "frame", frame_count - 1, animation_duration)
	await tween.finished
	queue_free()

extends Polygon2D

@export var reveal_delay: float = 0.8
@export var reveal_fade_duration: float = 0.9

func _ready() -> void:
	color = Color.BLACK

func start_reveal() -> void:
	modulate.a = 1.0
	visible = true

	var tween := create_tween()
	tween.tween_interval(reveal_delay)
	tween.tween_property(self, "modulate:a", 0.0, reveal_fade_duration)
	tween.tween_callback(queue_free)

extends Parallax2D

# Keep centered artwork anchored around the camera center. Parallax2D's
# automatic screen offset includes half the viewport size, even with camera zoom.
var _art_offset: Vector2


func _ready() -> void:
	_art_offset = scroll_offset
	get_viewport().size_changed.connect(_update_center_offset)
	_update_center_offset()


func _update_center_offset() -> void:
	scroll_offset = _art_offset + get_viewport_rect().size * 0.5 * (Vector2.ONE - scroll_scale)

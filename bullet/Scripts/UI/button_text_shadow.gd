extends RefCounted

static func apply(button: Button) -> void:
	if button.has_node("TextShadow"):
		return
	var shadow := Label.new()
	shadow.name = "TextShadow"
	shadow.text = button.text
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.show_behind_parent = true
	shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shadow.add_theme_font_override("font", button.get_theme_font("font"))
	shadow.add_theme_font_size_override("font_size", button.get_theme_font_size("font_size"))
	shadow.add_theme_color_override("font_color", Color(0, 0, 0, 0.85))
	shadow.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	shadow.add_theme_constant_override("shadow_offset_x", 0)
	shadow.add_theme_constant_override("shadow_offset_y", 0)
	button.add_child(shadow)
	# Explicit offsets avoid the label's minimum size widening its anchored rect.
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.offset_left = 3.0
	shadow.offset_top = 3.0
	shadow.offset_right = 3.0
	shadow.offset_bottom = 3.0

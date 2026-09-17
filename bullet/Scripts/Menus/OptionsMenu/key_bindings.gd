extends Control

signal closed()

const ACTION_LABELS := {
	"left": "Move Left",
	"right": "Move Right",
	"jump": "Jump",
	"drop_through": "Drop Through",
	"shoot": "Shoot",
	"bullet_time": "Bullet Time",
	"interact": "Interact",
	"restart": "Restart",
	"menu": "Pause Menu",
}

var awaiting_action := ""
var binding_buttons: Dictionary = {}
var status_label: Label

func _ready() -> void:
	hide()
	_build_page()
	_refresh_bindings()

func open_page() -> void:
	_refresh_bindings()
	status_label.text = "Select an action, then press a key. Escape cancels."
	show()

func close_page() -> void:
	awaiting_action = ""
	SettingsManager.is_capturing_binding = false
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	if awaiting_action.is_empty():
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close_page()
		return
	get_viewport().set_input_as_handled()
	if event.keycode == KEY_ESCAPE:
		awaiting_action = ""
		SettingsManager.is_capturing_binding = false
		status_label.text = "Binding canceled."
		_refresh_bindings()
		return
	if event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
		SettingsManager.set_key_binding(awaiting_action, 0)
		_finish_capture("Key cleared.")
		return
	var keycode: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if keycode == 0 or keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		status_label.text = "Press a regular key, or Escape to cancel."
		return
	for action in SettingsManager.REBINDABLE_ACTIONS:
		if action != awaiting_action and SettingsManager.action_has_key(action, keycode):
			status_label.text = "%s is already bound to %s." % [OS.get_keycode_string(keycode), ACTION_LABELS[action]]
			return
	SettingsManager.set_key_binding(awaiting_action, keycode)
	_finish_capture("Binding saved.")

func _finish_capture(message: String) -> void:
	awaiting_action = ""
	SettingsManager.is_capturing_binding = false
	status_label.text = message
	_refresh_bindings()

func _refresh_bindings() -> void:
	for action in binding_buttons:
		binding_buttons[action].text = "Press a key..." if action == awaiting_action else SettingsManager.get_key_binding_text(action)

func _on_binding_pressed(action: String) -> void:
	awaiting_action = action
	SettingsManager.is_capturing_binding = true
	status_label.text = "Press a key for %s. Backspace clears it." % ACTION_LABELS[action]
	_refresh_bindings()

func _build_page() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.08, 0.055, 0.04, 0.96)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 24
	scroll.offset_top = 20
	scroll.offset_right = -24
	scroll.offset_bottom = -20
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 400
	column.add_theme_constant_override("separation", 10)
	center.add_child(column)
	var title := Label.new()
	title.text = "Key Bindings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	column.add_child(title)
	for action in SettingsManager.REBINDABLE_ACTIONS:
		var row := HBoxContainer.new()
		column.add_child(row)
		var label := Label.new()
		label.text = ACTION_LABELS[action]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 24)
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(155, 38)
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_on_binding_pressed.bind(action))
		row.add_child(button)
		binding_buttons[action] = button
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 52
	column.add_child(status_label)
	var reset := Button.new()
	reset.text = "Restore Defaults"
	reset.pressed.connect(func() -> void:
		awaiting_action = ""
		SettingsManager.is_capturing_binding = false
		SettingsManager.reset_key_bindings()
		status_label.text = "Default keys restored."
		_refresh_bindings()
	)
	column.add_child(reset)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(close_page)
	column.add_child(back)

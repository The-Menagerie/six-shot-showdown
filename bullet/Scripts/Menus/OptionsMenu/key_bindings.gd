extends Control

signal closed()

@export var show_menu_background := true

const MENU_BACKGROUND := preload("res://Assets/Tilesets/KeyboardAndMouse/MainMenuBackground.png")
const MENU_PANEL := preload("res://Assets/Tilesets/KeyboardAndMouse/PauseMenu.png")
const BUTTON_SOUND := preload("res://Assets/SoundEffects/WoodenBlock.wav")
const ACTION_LABELS := {
	"left": "Move Left",
	"right": "Move Right",
	"jump": "Jump",
	"down": "Down",
	"shoot": "Shoot",
	"bullet_time": "Bullet Time",
	"interact": "Interact",
	"restart": "Restart",
	"menu": "Pause Menu",
}

var awaiting_action := ""
var awaiting_slot := -1
var binding_device := SettingsManager.INPUT_DEVICE_KEYBOARD
var binding_buttons: Dictionary = {}
var binding_rows: Dictionary = {}
var status_label: Label
var device_toggle: Button
var stick_options: VBoxContainer
var stick_swap_button: Button
var invert_move_horizontal_toggle: CheckButton
var invert_move_vertical_toggle: CheckButton
var invert_aim_horizontal_toggle: CheckButton
var invert_aim_vertical_toggle: CheckButton
var aim_speed_slider: HSlider
var button_sound: AudioStreamPlayer

func _ready() -> void:
	hide()
	_build_page()
	_refresh_bindings()

func open_page() -> void:
	_refresh_bindings()
	status_label.text = _get_device_prompt()
	show()
	SettingsManager.focus_first_menu_control(self)

func close_page() -> void:
	awaiting_action = ""
	awaiting_slot = -1
	SettingsManager.is_capturing_binding = false
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if awaiting_action.is_empty():
		if SettingsManager.is_menu_back_event(event):
			get_viewport().set_input_as_handled()
			_on_back_pressed()
		return
	if SettingsManager.is_menu_back_event(event):
		awaiting_action = ""
		awaiting_slot = -1
		SettingsManager.is_capturing_binding = false
		status_label.text = "Binding canceled."
		_play_button_sound()
		_refresh_bindings()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE):
		SettingsManager.set_input_binding(awaiting_action, binding_device, awaiting_slot, "", 0)
		_finish_capture("Binding cleared.")
		get_viewport().set_input_as_handled()
		return
	var binding_type := ""
	var code: int = 0
	var axis_value := 0.0
	var binding_name := ""
	if binding_device == SettingsManager.INPUT_DEVICE_KEYBOARD and event is InputEventMouseButton and event.pressed:
		binding_type = "mouse"
		code = event.button_index
		binding_name = SettingsManager.get_mouse_button_name(code)
	elif binding_device == SettingsManager.INPUT_DEVICE_KEYBOARD and event is InputEventKey and event.pressed and not event.echo:
		binding_type = "key"
		code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code == 0 or code in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			status_label.text = "Press a regular key or mouse button, or Escape to cancel."
			return
		binding_name = OS.get_keycode_string(code)
	elif binding_device == SettingsManager.INPUT_DEVICE_CONTROLLER and event is InputEventJoypadButton and event.pressed:
		binding_type = "joy_button"
		code = event.button_index
		binding_name = SettingsManager.get_controller_button_name(code)
	elif binding_device == SettingsManager.INPUT_DEVICE_CONTROLLER and event is InputEventJoypadMotion and ((SettingsManager.is_controller_trigger_axis(event.axis) and event.axis_value >= 0.5) or (not SettingsManager.is_controller_trigger_axis(event.axis) and absf(event.axis_value) >= 0.5)):
		if awaiting_action == "jump":
			status_label.text = "Press a controller button for Jump."
			return
		binding_type = "joy_axis"
		code = event.axis
		axis_value = 1.0 if SettingsManager.is_controller_trigger_axis(code) else signf(event.axis_value)
		binding_name = SettingsManager.get_controller_axis_name(code)
		if not SettingsManager.is_controller_trigger_axis(code):
			binding_name += " +" if axis_value > 0.0 else " -"
	else:
		return
	get_viewport().set_input_as_handled()
	for action in SettingsManager.get_rebindable_actions():
		if action != awaiting_action and SettingsManager.action_has_binding(action, binding_type, code, axis_value):
			status_label.text = "%s is already bound to %s." % [binding_name, _get_action_label(action)]
			return
	var current_bindings := SettingsManager.get_input_bindings(awaiting_action, binding_device)
	for slot in current_bindings.size():
		if slot == awaiting_slot:
			continue
		var current_binding: Dictionary = current_bindings[slot]
		var same_axis_direction := binding_type != "joy_axis" or SettingsManager.is_controller_trigger_axis(code) or signf(float(current_binding.get("axis_value", 0.0))) == signf(axis_value)
		if current_binding.get("type") == binding_type and int(current_binding.get("code", 0)) == code and same_axis_direction:
			status_label.text = "%s is already bound to %s." % [binding_name, _get_action_label(awaiting_action)]
			return
	SettingsManager.set_input_binding(awaiting_action, binding_device, awaiting_slot, binding_type, code, axis_value)
	_finish_capture("Binding saved.")

func _finish_capture(message: String) -> void:
	awaiting_action = ""
	awaiting_slot = -1
	SettingsManager.is_capturing_binding = false
	status_label.text = message
	_refresh_bindings()

func _refresh_bindings() -> void:
	for action in binding_buttons:
		var action_name := String(action)
		if binding_device == SettingsManager.INPUT_DEVICE_CONTROLLER:
			binding_rows[action].visible = not SettingsManager.is_stick_direction_action(action_name)
		else:
			binding_rows[action].visible = not action_name.begins_with("aim_")
		var buttons: Array = binding_buttons[action]
		for slot in buttons.size():
			buttons[slot].visible = binding_device == SettingsManager.INPUT_DEVICE_KEYBOARD or slot == 0
			buttons[slot].text = "Press input..." if action == awaiting_action and slot == awaiting_slot else SettingsManager.get_input_binding_text(action, binding_device, slot)
	if device_toggle != null:
		device_toggle.text = "Input: Controller" if binding_device == SettingsManager.INPUT_DEVICE_CONTROLLER else "Input: Keyboard & Mouse"
	_refresh_stick_options()

func _on_binding_pressed(action: String, slot: int) -> void:
	_play_button_sound()
	awaiting_action = action
	awaiting_slot = slot
	SettingsManager.is_capturing_binding = true
	status_label.text = "%s for %s. Backspace clears it." % [_get_device_prompt(), _get_action_label(action)]
	_refresh_bindings()

func _get_device_prompt() -> String:
	if binding_device == SettingsManager.INPUT_DEVICE_CONTROLLER:
		return "Press a controller button or move an axis"
	return "Press a key or mouse button"

func _on_device_toggle_pressed() -> void:
	_play_button_sound()
	awaiting_action = ""
	awaiting_slot = -1
	SettingsManager.is_capturing_binding = false
	binding_device = SettingsManager.INPUT_DEVICE_CONTROLLER if binding_device == SettingsManager.INPUT_DEVICE_KEYBOARD else SettingsManager.INPUT_DEVICE_KEYBOARD
	status_label.text = _get_device_prompt()
	_refresh_bindings()

func _refresh_stick_options() -> void:
	if stick_options == null:
		return
	stick_options.visible = binding_device == SettingsManager.INPUT_DEVICE_CONTROLLER
	stick_swap_button.text = "Movement: Right Stick | Aim: Left Stick" if SettingsManager.controller_sticks_swapped else "Movement: Left Stick | Aim: Right Stick"
	invert_move_horizontal_toggle.set_pressed_no_signal(SettingsManager.invert_move_horizontal)
	invert_move_vertical_toggle.set_pressed_no_signal(SettingsManager.invert_move_vertical)
	invert_aim_horizontal_toggle.set_pressed_no_signal(SettingsManager.invert_aim_horizontal)
	invert_aim_vertical_toggle.set_pressed_no_signal(SettingsManager.invert_aim_vertical)
	aim_speed_slider.set_value_no_signal(SettingsManager.aim_speed)

func _on_stick_swap_pressed() -> void:
	_play_button_sound()
	SettingsManager.set_controller_sticks_swapped(not SettingsManager.controller_sticks_swapped)
	_refresh_stick_options()

func _on_invert_move_horizontal_toggled(enabled: bool) -> void:
	_play_button_sound()
	SettingsManager.set_invert_move_horizontal(enabled)

func _on_invert_move_vertical_toggled(enabled: bool) -> void:
	_play_button_sound()
	SettingsManager.set_invert_move_vertical(enabled)

func _on_invert_aim_horizontal_toggled(enabled: bool) -> void:
	_play_button_sound()
	SettingsManager.set_invert_aim_horizontal(enabled)

func _on_invert_aim_vertical_toggled(enabled: bool) -> void:
	_play_button_sound()
	SettingsManager.set_invert_aim_vertical(enabled)

func _on_back_pressed() -> void:
	_play_button_sound()
	close_page()

func _play_button_sound() -> void:
	button_sound.play()

func _get_action_label(action: String) -> String:
	return String(ACTION_LABELS.get(action, action.replace("_", " ").capitalize()))

func _build_page() -> void:
	button_sound = AudioStreamPlayer.new()
	button_sound.stream = BUTTON_SOUND
	button_sound.bus = &"sfx"
	add_child(button_sound)
	var backdrop := TextureRect.new()
	backdrop.texture = MENU_BACKGROUND
	backdrop.visible = show_menu_background
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var border := NinePatchRect.new()
	border.texture = MENU_PANEL
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	border.offset_left = -290
	border.offset_top = -440
	border.offset_right = 290
	border.offset_bottom = 440
	border.set_patch_margin(SIDE_LEFT, 20)
	border.set_patch_margin(SIDE_TOP, 35)
	border.set_patch_margin(SIDE_RIGHT, 20)
	border.set_patch_margin(SIDE_BOTTOM, 35)
	add_child(border)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	scroll.offset_left = -260
	scroll.offset_top = -405
	scroll.offset_right = 260
	scroll.offset_bottom = 405
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
	for action in SettingsManager.get_rebindable_actions():
		var row := HBoxContainer.new()
		column.add_child(row)
		binding_rows[action] = row
		var label := Label.new()
		label.text = _get_action_label(action)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 24)
		row.add_child(label)
		var buttons: Array[Button] = []
		for slot in SettingsManager.MAX_BINDINGS_PER_ACTION:
			var button := Button.new()
			button.custom_minimum_size = Vector2(145, 38)
			button.add_theme_font_size_override("font_size", 20)
			button.pressed.connect(_on_binding_pressed.bind(action, slot))
			row.add_child(button)
			buttons.append(button)
		binding_buttons[action] = buttons
	stick_options = VBoxContainer.new()
	stick_options.add_theme_constant_override("separation", 6)
	column.add_child(stick_options)
	var stick_title := Label.new()
	stick_title.text = "Stick Setup"
	stick_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stick_title.add_theme_font_size_override("font_size", 26)
	stick_options.add_child(stick_title)
	stick_swap_button = Button.new()
	stick_swap_button.pressed.connect(_on_stick_swap_pressed)
	stick_options.add_child(stick_swap_button)
	invert_move_horizontal_toggle = CheckButton.new()
	invert_move_horizontal_toggle.text = "Invert Movement Horizontal"
	invert_move_horizontal_toggle.toggled.connect(_on_invert_move_horizontal_toggled)
	stick_options.add_child(invert_move_horizontal_toggle)
	invert_move_vertical_toggle = CheckButton.new()
	invert_move_vertical_toggle.text = "Invert Movement Vertical"
	invert_move_vertical_toggle.toggled.connect(_on_invert_move_vertical_toggled)
	stick_options.add_child(invert_move_vertical_toggle)
	var aim_speed_label := Label.new()
	aim_speed_label.text = "Aim Speed"
	aim_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aim_speed_label.add_theme_font_size_override("font_size", 24)
	stick_options.add_child(aim_speed_label)
	aim_speed_slider = HSlider.new()
	aim_speed_slider.custom_minimum_size = Vector2(240, 0)
	aim_speed_slider.min_value = SettingsManager.MIN_AIM_SPEED
	aim_speed_slider.max_value = SettingsManager.MAX_AIM_SPEED
	aim_speed_slider.step = 10.0
	aim_speed_slider.value = SettingsManager.aim_speed
	aim_speed_slider.value_changed.connect(SettingsManager.set_aim_speed)
	stick_options.add_child(aim_speed_slider)
	invert_aim_horizontal_toggle = CheckButton.new()
	invert_aim_horizontal_toggle.text = "Invert Aim Horizontal"
	invert_aim_horizontal_toggle.toggled.connect(_on_invert_aim_horizontal_toggled)
	stick_options.add_child(invert_aim_horizontal_toggle)
	invert_aim_vertical_toggle = CheckButton.new()
	invert_aim_vertical_toggle.text = "Invert Aim Vertical"
	invert_aim_vertical_toggle.toggled.connect(_on_invert_aim_vertical_toggled)
	stick_options.add_child(invert_aim_vertical_toggle)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 52
	column.add_child(status_label)
	device_toggle = Button.new()
	device_toggle.pressed.connect(_on_device_toggle_pressed)
	column.add_child(device_toggle)
	var reset := Button.new()
	reset.text = "Restore Defaults"
	reset.pressed.connect(func() -> void:
		_play_button_sound()
		awaiting_action = ""
		awaiting_slot = -1
		SettingsManager.is_capturing_binding = false
		SettingsManager.reset_key_bindings()
		status_label.text = "Default bindings restored."
		_refresh_bindings()
	)
	column.add_child(reset)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(_on_back_pressed)
	column.add_child(back)

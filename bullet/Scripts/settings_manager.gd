extends Node

signal input_bindings_changed
signal input_device_changed(device_type: String)

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "gameplay"
const SKIP_TUTORIAL_KEY := "skip_tutorial"
const SKIP_CUTSCENES_KEY := "skip_cutscenes"
const AIM_SPEED_KEY := "aim_speed"
const STICKS_SWAPPED_KEY := "controller_sticks_swapped"
const INVERT_MOVE_HORIZONTAL_KEY := "invert_move_horizontal"
const INVERT_MOVE_VERTICAL_KEY := "invert_move_vertical"
const INVERT_AIM_HORIZONTAL_KEY := "invert_aim_horizontal"
const INVERT_AIM_VERTICAL_KEY := "invert_aim_vertical"
const BINDINGS_SECTION := "key_bindings"
const MAX_BINDINGS_PER_ACTION := 2
const INPUT_DEVICE_KEYBOARD := "keyboard"
const INPUT_DEVICE_CONTROLLER := "controller"
const STICK_DIRECTION_ACTIONS := ["left", "right", "down", "aim_left", "aim_right", "aim_up", "aim_down"]
const CURSOR_HOTSPOT := Vector2(10, 10)
const UI_TEXT_SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.85)
const UI_TEXT_SHADOW_OFFSET := Vector2i(3, 3)
const UI_FOCUS_COLOR := Color(0.9098039, 0.4, 0.2901961, 1)
const DEFAULT_AIM_SPEED := 900.0
const MIN_AIM_SPEED := 150.0
const MAX_AIM_SPEED := 2200.0
const CONTROLLER_SLIDER_SPEED := 0.75
const CONTROLLER_SLIDER_DPAD_STEP := 0.1
const INPUT_DEVICE_AXIS_THRESHOLD := 0.2

@export var reticle_edge_padding : float = 4.0

var reticle = load("res://Assets/Tilesets/StrangeCowboy/Player/reticle_norm.png")
var reticle_clicked = load("res://Assets/Tilesets/StrangeCowboy/Player/reticle_clicked.png")

var skip_tutorial := false
var skip_cutscenes := false
var aim_speed := DEFAULT_AIM_SPEED
var controller_sticks_swapped := false
var invert_move_horizontal := false
var invert_move_vertical := false
var invert_aim_horizontal := false
var invert_aim_vertical := false
var is_capturing_binding := false
var last_input_device := INPUT_DEVICE_KEYBOARD

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_controller_stick_settings(false)
	_limit_rebindable_inputs()
	_ensure_controller_ui_actions()
	apply_custom_cursor()
	var tree := get_tree()
	if tree != null and not tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.connect(_on_tree_node_added)
	call_deferred("_apply_text_shadows_to_existing_controls")

func _process(delta: float) -> void:
	if is_menu_context():
		_adjust_focused_slider_with_stick(delta)
		return
	var aim_input := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim_input == Vector2.ZERO:
		return

	var viewport := get_viewport()
	if viewport == null:
		return

	var viewport_rect := viewport.get_visible_rect()
	var next_mouse_position := viewport.get_mouse_position() + aim_input * aim_speed * delta
	next_mouse_position.x = clampf(
		next_mouse_position.x,
		viewport_rect.position.x + reticle_edge_padding,
		viewport_rect.end.x - reticle_edge_padding
	)
	next_mouse_position.y = clampf(
		next_mouse_position.y,
		viewport_rect.position.y + reticle_edge_padding,
		viewport_rect.end.y - reticle_edge_padding
	)

	viewport.warp_mouse(next_mouse_position)

func is_menu_context() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	if tree.paused:
		return true
	var current_scene := tree.current_scene
	if current_scene == null or current_scene.scene_file_path.is_empty():
		return false
	var scene_path := current_scene.scene_file_path
	return scene_path.begins_with("res://Scenes/UI/MainMenu/") or scene_path == "res://Scenes/Cutscene.tscn"

func is_menu_back_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return event.pressed and event.button_index == 1
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE

func _input(event: InputEvent) -> void:
	_update_last_input_device(event)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_apply_cursor_texture(reticle_clicked if event.pressed else reticle)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return

	if event.is_echo():
		return
	if is_capturing_binding:
		return
	if is_menu_context() and event is InputEventJoypadButton and event.pressed and event.button_index in [13, 14]:
		if _adjust_focused_slider_with_dpad(-1.0 if event.button_index == 13 else 1.0):
			get_viewport().set_input_as_handled()
			return

func _update_last_input_device(event: InputEvent) -> void:
	var next_device := ""
	if event is InputEventJoypadButton and event.pressed:
		next_device = INPUT_DEVICE_CONTROLLER
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= INPUT_DEVICE_AXIS_THRESHOLD:
		next_device = INPUT_DEVICE_CONTROLLER
	elif event is InputEventKey and event.pressed and not event.echo:
		next_device = INPUT_DEVICE_KEYBOARD
	elif event is InputEventMouseButton and event.pressed:
		next_device = INPUT_DEVICE_KEYBOARD

	if next_device.is_empty() or next_device == last_input_device:
		return
	last_input_device = next_device
	input_device_changed.emit(last_input_device)


func _ensure_controller_ui_actions() -> void:
	var accept_event := InputEventJoypadButton.new()
	accept_event.button_index = 0
	if not InputMap.action_has_event("ui_accept", accept_event):
		InputMap.action_add_event("ui_accept", accept_event)
	_ensure_controller_ui_axis("ui_left", 0, -1.0)
	_ensure_controller_ui_axis("ui_right", 0, 1.0)
	_ensure_controller_ui_axis("ui_up", 1, -1.0)
	_ensure_controller_ui_axis("ui_down", 1, 1.0)

func _adjust_focused_slider_with_stick(delta: float) -> void:
	var slider := get_viewport().gui_get_focus_owner() as HSlider
	if slider == null:
		return
	var joypads := Input.get_connected_joypads()
	if joypads.is_empty():
		return
	var direction := Input.get_joy_axis(int(joypads[0]), 0)
	if absf(direction) < 0.25:
		return
	var strength := (absf(direction) - 0.25) / 0.75
	slider.value += signf(direction) * strength * (slider.max_value - slider.min_value) * CONTROLLER_SLIDER_SPEED * delta

func _adjust_focused_slider_with_dpad(direction: float) -> bool:
	var slider := get_viewport().gui_get_focus_owner() as HSlider
	if slider == null:
		return false
	slider.value += direction * (slider.max_value - slider.min_value) * CONTROLLER_SLIDER_DPAD_STEP
	return true

func _ensure_controller_ui_axis(action: String, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var axis_event := InputEventJoypadMotion.new()
	axis_event.axis = axis
	axis_event.axis_value = axis_value
	if not InputMap.action_has_event(action, axis_event):
		InputMap.action_add_event(action, axis_event)

func focus_first_menu_control(root: Node) -> void:
	call_deferred("_focus_first_menu_control", root)

func _focus_first_menu_control(root: Node) -> void:
	if not is_instance_valid(root):
		return
	for node in root.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree() or control.focus_mode == Control.FOCUS_NONE:
			continue
		if control is BaseButton and (control as BaseButton).disabled:
			continue
		control.grab_focus()
		return

func apply_custom_cursor() -> void:
	_apply_cursor_texture(reticle)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _apply_cursor_texture(texture: Resource) -> void:
	Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	Input.set_custom_mouse_cursor(texture, Input.CURSOR_POINTING_HAND, CURSOR_HOTSPOT)
	Input.set_custom_mouse_cursor(texture, Input.CURSOR_FDIAGSIZE, CURSOR_HOTSPOT)

func _apply_text_shadows_to_existing_controls() -> void:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return

	_apply_text_shadow_to_subtree(tree.root)

func _on_tree_node_added(node: Node) -> void:
	_apply_text_shadow_to_subtree(node)

func _apply_text_shadow_to_subtree(node: Node) -> void:
	if node == null:
		return

	if node is Control:
		_apply_text_shadow_to_control(node as Control)

	for child in node.get_children():
		_apply_text_shadow_to_subtree(child)

func _apply_text_shadow_to_control(control: Control) -> void:
	if not control.has_theme_color_override("font_shadow_color"):
		control.add_theme_color_override("font_shadow_color", UI_TEXT_SHADOW_COLOR)
	if not control.has_theme_constant_override("shadow_offset_x"):
		control.add_theme_constant_override("shadow_offset_x", UI_TEXT_SHADOW_OFFSET.x)
	if not control.has_theme_constant_override("shadow_offset_y"):
		control.add_theme_constant_override("shadow_offset_y", UI_TEXT_SHADOW_OFFSET.y)
	if control is BaseButton and not control.has_theme_color_override("font_focus_color"):
		control.add_theme_color_override("font_focus_color", UI_FOCUS_COLOR)

func _click_hovered_ui_control() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return

	var hovered_control: Control = viewport.gui_get_hovered_control()
	if hovered_control == null:
		return
	if not _should_treat_accept_as_click(hovered_control):
		return
	viewport.set_input_as_handled()

	var mouse_position := viewport.get_mouse_position()
	var mouse_press := InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.pressed = true
	mouse_press.position = mouse_position
	mouse_press.global_position = mouse_position
	Input.parse_input_event(mouse_press)

	var mouse_release := InputEventMouseButton.new()
	mouse_release.button_index = MOUSE_BUTTON_LEFT
	mouse_release.pressed = false
	mouse_release.position = mouse_position
	mouse_release.global_position = mouse_position
	Input.parse_input_event(mouse_release)

func _should_treat_accept_as_click(control: Control) -> bool:
	if control == null:
		return false
	if not (control is BaseButton or control is OptionButton or control is HSlider):
		return false
	return is_menu_context()

func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		skip_tutorial = false
		skip_cutscenes = false
		aim_speed = DEFAULT_AIM_SPEED
		return
	for action in get_rebindable_actions():
		var saved_action: String = action
		if action == "down" and not config.has_section_key(BINDINGS_SECTION, action) and config.has_section_key(BINDINGS_SECTION, "drop_through"):
			saved_action = "drop_through"
		if config.has_section_key(BINDINGS_SECTION, saved_action):
			var saved_binding: Variant = config.get_value(BINDINGS_SECTION, saved_action)
			if saved_binding is Array:
				set_input_bindings(action, INPUT_DEVICE_KEYBOARD, saved_binding, false)
			elif saved_binding is Dictionary:
				if saved_binding.has(INPUT_DEVICE_KEYBOARD) or saved_binding.has(INPUT_DEVICE_CONTROLLER):
					if saved_binding.has(INPUT_DEVICE_KEYBOARD):
						set_input_bindings(action, INPUT_DEVICE_KEYBOARD, saved_binding[INPUT_DEVICE_KEYBOARD], false)
					if saved_binding.has(INPUT_DEVICE_CONTROLLER):
						set_input_bindings(action, INPUT_DEVICE_CONTROLLER, saved_binding[INPUT_DEVICE_CONTROLLER], false)
				else:
					set_input_bindings(action, INPUT_DEVICE_KEYBOARD, [saved_binding], false)
			else:
				# Settings from the keyboard-only binding system.
				set_input_bindings(action, INPUT_DEVICE_KEYBOARD, [{"type": "key", "code": int(saved_binding)}], false)

	skip_tutorial = bool(config.get_value(SETTINGS_SECTION, SKIP_TUTORIAL_KEY, false))
	skip_cutscenes = bool(config.get_value(SETTINGS_SECTION, SKIP_CUTSCENES_KEY, false))
	aim_speed = clampf(
		float(config.get_value(SETTINGS_SECTION, AIM_SPEED_KEY, DEFAULT_AIM_SPEED)),
		MIN_AIM_SPEED,
		MAX_AIM_SPEED
	)
	controller_sticks_swapped = bool(config.get_value(SETTINGS_SECTION, STICKS_SWAPPED_KEY, false))
	invert_move_horizontal = bool(config.get_value(SETTINGS_SECTION, INVERT_MOVE_HORIZONTAL_KEY, false))
	invert_move_vertical = bool(config.get_value(SETTINGS_SECTION, INVERT_MOVE_VERTICAL_KEY, false))
	invert_aim_horizontal = bool(config.get_value(SETTINGS_SECTION, INVERT_AIM_HORIZONTAL_KEY, false))
	invert_aim_vertical = bool(config.get_value(SETTINGS_SECTION, INVERT_AIM_VERTICAL_KEY, false))

func set_skip_tutorial(enabled: bool) -> void:
	if skip_tutorial == enabled:
		return

	skip_tutorial = enabled
	save_settings()

func set_skip_cutscenes(enabled: bool) -> void:
	if skip_cutscenes == enabled:
		return

	skip_cutscenes = enabled
	save_settings()

func set_aim_speed(value: float) -> void:
	var clamped_value := clampf(value, MIN_AIM_SPEED, MAX_AIM_SPEED)
	if is_equal_approx(aim_speed, clamped_value):
		return

	aim_speed = clamped_value
	save_settings()

func set_controller_sticks_swapped(enabled: bool) -> void:
	controller_sticks_swapped = enabled
	apply_controller_stick_settings()

func set_invert_move_horizontal(enabled: bool) -> void:
	invert_move_horizontal = enabled
	apply_controller_stick_settings()

func set_invert_move_vertical(enabled: bool) -> void:
	invert_move_vertical = enabled
	apply_controller_stick_settings()

func set_invert_aim_horizontal(enabled: bool) -> void:
	invert_aim_horizontal = enabled
	apply_controller_stick_settings()

func set_invert_aim_vertical(enabled: bool) -> void:
	invert_aim_vertical = enabled
	apply_controller_stick_settings()

func apply_controller_stick_settings(persist: bool = true) -> void:
	var move_x_axis := 2 if controller_sticks_swapped else 0
	var move_y_axis := 3 if controller_sticks_swapped else 1
	var aim_x_axis := 0 if controller_sticks_swapped else 2
	var aim_y_axis := 1 if controller_sticks_swapped else 3
	var move_x_sign := -1.0 if invert_move_horizontal else 1.0
	var move_y_sign := -1.0 if invert_move_vertical else 1.0
	var aim_x_sign := -1.0 if invert_aim_horizontal else 1.0
	var aim_y_sign := -1.0 if invert_aim_vertical else 1.0
	_set_action_joy_axis("left", move_x_axis, -1.0 * move_x_sign)
	_set_action_joy_axis("right", move_x_axis, 1.0 * move_x_sign)
	_set_action_joy_axis("jump", move_y_axis, -1.0 * move_y_sign)
	_set_action_joy_axis("down", move_y_axis, 1.0 * move_y_sign)
	_set_action_joy_axis("aim_left", aim_x_axis, -1.0 * aim_x_sign)
	_set_action_joy_axis("aim_right", aim_x_axis, 1.0 * aim_x_sign)
	_set_action_joy_axis("aim_up", aim_y_axis, -1.0 * aim_y_sign)
	_set_action_joy_axis("aim_down", aim_y_axis, 1.0 * aim_y_sign)
	if persist:
		save_settings()
	input_bindings_changed.emit()

func _set_action_joy_axis(action: String, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			InputMap.action_erase_event(action, event)
	var axis_event := InputEventJoypadMotion.new()
	axis_event.axis = axis
	axis_event.axis_value = axis_value
	InputMap.action_add_event(action, axis_event)

func is_stick_direction_action(action: String) -> bool:
	return STICK_DIRECTION_ACTIONS.has(action)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, SKIP_TUTORIAL_KEY, skip_tutorial)
	config.set_value(SETTINGS_SECTION, SKIP_CUTSCENES_KEY, skip_cutscenes)
	config.set_value(SETTINGS_SECTION, AIM_SPEED_KEY, aim_speed)
	config.set_value(SETTINGS_SECTION, STICKS_SWAPPED_KEY, controller_sticks_swapped)
	config.set_value(SETTINGS_SECTION, INVERT_MOVE_HORIZONTAL_KEY, invert_move_horizontal)
	config.set_value(SETTINGS_SECTION, INVERT_MOVE_VERTICAL_KEY, invert_move_vertical)
	config.set_value(SETTINGS_SECTION, INVERT_AIM_HORIZONTAL_KEY, invert_aim_horizontal)
	config.set_value(SETTINGS_SECTION, INVERT_AIM_VERTICAL_KEY, invert_aim_vertical)
	config.save(SETTINGS_PATH)

func get_rebindable_actions() -> Array[String]:
	var actions: Array[String] = []
	for action_name in InputMap.get_actions():
		var action: String = String(action_name)
		if not action.begins_with("ui_") and ProjectSettings.has_setting("input/" + action):
			actions.append(action)
	return actions

func get_max_bindings_for_device(device_type: String) -> int:
	return 1 if device_type == INPUT_DEVICE_CONTROLLER else MAX_BINDINGS_PER_ACTION

func action_has_binding(action: String, binding_type: String, code: int, axis_value: float = 0.0) -> bool:
	for event in InputMap.action_get_events(action):
		if binding_type == "key" and event is InputEventKey and (event.physical_keycode == code or (event.physical_keycode == 0 and event.keycode == code)):
			return true
		if binding_type == "mouse" and event is InputEventMouseButton and event.button_index == code:
			return true
		if binding_type == "joy_button" and event is InputEventJoypadButton and event.button_index == code:
			return true
		if binding_type == "joy_axis" and event is InputEventJoypadMotion and event.axis == code and (is_controller_trigger_axis(code) or signf(event.axis_value) == signf(axis_value)):
			return true
	return false

func get_input_bindings(action: String, device_type: String) -> Array:
	var bindings: Array = []
	for event in InputMap.action_get_events(action):
		if device_type == INPUT_DEVICE_KEYBOARD and event is InputEventKey:
			var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			bindings.append({"type": "key", "code": code})
		elif device_type == INPUT_DEVICE_KEYBOARD and event is InputEventMouseButton:
			bindings.append({"type": "mouse", "code": int(event.button_index)})
		elif device_type == INPUT_DEVICE_CONTROLLER and event is InputEventJoypadButton:
			bindings.append({"type": "joy_button", "code": int(event.button_index)})
		elif device_type == INPUT_DEVICE_CONTROLLER and event is InputEventJoypadMotion and not _is_managed_stick_axis_action(action):
			var direction := 1.0 if is_controller_trigger_axis(event.axis) else signf(event.axis_value)
			bindings.append({"type": "joy_axis", "code": int(event.axis), "axis_value": direction})
		if bindings.size() == get_max_bindings_for_device(device_type):
			break
	return bindings

func get_input_binding_text(action: String, device_type: String, slot: int) -> String:
	var bindings := get_input_bindings(action, device_type)
	if slot < 0 or slot >= bindings.size():
		return "Unbound"
	var binding: Dictionary = bindings[slot]
	var code := int(binding.get("code", 0))
	match String(binding.get("type", "key")):
		"mouse": return get_mouse_button_name(code)
		"joy_button": return get_controller_button_name(code)
		"joy_axis":
			if is_controller_trigger_axis(code):
				return get_controller_axis_name(code)
			var direction := "+" if float(binding.get("axis_value", 1.0)) > 0.0 else "-"
			return "%s %s" % [get_controller_axis_name(code), direction]
		_: return OS.get_keycode_string(code)

func get_mouse_button_name(button_index: int) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT: return "Left Click"
		MOUSE_BUTTON_RIGHT: return "Right Click"
		MOUSE_BUTTON_MIDDLE: return "Middle Click"
		MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
		MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
		MOUSE_BUTTON_XBUTTON1: return "Mouse Button 4"
		MOUSE_BUTTON_XBUTTON2: return "Mouse Button 5"
		_: return "Mouse Button %d" % button_index

func get_controller_button_name(button_index: int) -> String:
	var names := [
		"A / Cross", "B / Circle", "X / Square", "Y / Triangle",
		"Back / Select", "Guide", "Start", "Left Stick", "Right Stick",
		"Left Shoulder", "Right Shoulder", "D-Pad Up", "D-Pad Down",
		"D-Pad Left", "D-Pad Right", "Misc Button", "Paddle 1", "Paddle 2",
		"Paddle 3", "Paddle 4", "Touchpad",
	]
	return names[button_index] if button_index >= 0 and button_index < names.size() else "Controller Button %d" % button_index

func get_controller_axis_name(axis: int) -> String:
	var names := ["Left Stick X", "Left Stick Y", "Right Stick X", "Right Stick Y", "Left Trigger", "Right Trigger"]
	return names[axis] if axis >= 0 and axis < names.size() else "Controller Axis %d" % axis

func is_controller_trigger_axis(axis: int) -> bool:
	return axis == 4 or axis == 5

func set_input_binding(action: String, device_type: String, slot: int, binding_type: String, code: int, axis_value: float = 0.0) -> void:
	if not get_rebindable_actions().has(action):
		return
	var bindings := get_input_bindings(action, device_type)
	if binding_type.is_empty():
		if slot >= 0 and slot < bindings.size():
			bindings.remove_at(slot)
	elif slot >= 0 and slot < get_max_bindings_for_device(device_type):
		var new_binding := {"type": binding_type, "code": code}
		if binding_type == "joy_axis":
			new_binding["axis_value"] = 1.0 if is_controller_trigger_axis(code) else signf(axis_value)
		if slot < bindings.size():
			bindings[slot] = new_binding
		else:
			bindings.append(new_binding)
	set_input_bindings(action, device_type, bindings)

func set_input_bindings(action: String, device_type: String, bindings: Array, persist: bool = true) -> void:
	if not get_rebindable_actions().has(action):
		return
	for event in InputMap.action_get_events(action):
		if _event_matches_device(event, device_type) and not (device_type == INPUT_DEVICE_CONTROLLER and _is_managed_stick_axis_action(action) and event is InputEventJoypadMotion):
			InputMap.action_erase_event(action, event)
	for binding_value in bindings.slice(0, get_max_bindings_for_device(device_type)):
		if not binding_value is Dictionary:
			continue
		var binding: Dictionary = binding_value
		var binding_type := String(binding.get("type", "key"))
		var code := int(binding.get("code", 0))
		if code < 0 or (code == 0 and binding_type in ["key", "mouse"]):
			continue
		if binding_type == "mouse":
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = code
			InputMap.action_add_event(action, mouse_event)
		elif binding_type == "key":
			var key_event := InputEventKey.new()
			key_event.physical_keycode = code
			InputMap.action_add_event(action, key_event)
		elif binding_type == "joy_button":
			var joy_button_event := InputEventJoypadButton.new()
			joy_button_event.button_index = code
			InputMap.action_add_event(action, joy_button_event)
		elif binding_type == "joy_axis":
			if _is_managed_stick_axis_action(action):
				continue
			var joy_axis_event := InputEventJoypadMotion.new()
			joy_axis_event.axis = code
			joy_axis_event.axis_value = 1.0 if is_controller_trigger_axis(code) else signf(float(binding.get("axis_value", 1.0)))
			InputMap.action_add_event(action, joy_axis_event)
	if persist:
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)
		config.set_value(BINDINGS_SECTION, action, {
			INPUT_DEVICE_KEYBOARD: get_input_bindings(action, INPUT_DEVICE_KEYBOARD),
			INPUT_DEVICE_CONTROLLER: get_input_bindings(action, INPUT_DEVICE_CONTROLLER),
		})
		config.save(SETTINGS_PATH)
	input_bindings_changed.emit()

func _event_matches_device(event: InputEvent, device_type: String) -> bool:
	if device_type == INPUT_DEVICE_CONTROLLER:
		return event is InputEventJoypadButton or event is InputEventJoypadMotion
	return event is InputEventKey or event is InputEventMouseButton

func _is_managed_stick_axis_action(action: String) -> bool:
	return is_stick_direction_action(action) or action == "jump"

func _limit_rebindable_inputs() -> void:
	for action in get_rebindable_actions():
		set_input_bindings(action, INPUT_DEVICE_KEYBOARD, get_input_bindings(action, INPUT_DEVICE_KEYBOARD), false)
		set_input_bindings(action, INPUT_DEVICE_CONTROLLER, get_input_bindings(action, INPUT_DEVICE_CONTROLLER), false)

func reset_key_bindings() -> void:
	for action in get_rebindable_actions():
		for event in InputMap.action_get_events(action):
			if _event_matches_device(event, INPUT_DEVICE_KEYBOARD) or _event_matches_device(event, INPUT_DEVICE_CONTROLLER):
				InputMap.action_erase_event(action, event)
		var defaults: Dictionary = ProjectSettings.get_setting("input/" + action, {})
		for event in defaults.get("events", []):
			if _event_matches_device(event, INPUT_DEVICE_KEYBOARD) or _event_matches_device(event, INPUT_DEVICE_CONTROLLER):
				InputMap.action_add_event(action, event)
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	if config.has_section(BINDINGS_SECTION):
		config.erase_section(BINDINGS_SECTION)
	config.save(SETTINGS_PATH)
	controller_sticks_swapped = false
	invert_move_horizontal = false
	invert_move_vertical = false
	invert_aim_horizontal = false
	invert_aim_vertical = false
	apply_controller_stick_settings(false)
	save_settings()
	_limit_rebindable_inputs()

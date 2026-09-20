extends Control

@export_range(0.5, 10.0, 0.05) var fallback_cycle_seconds := 1.75

const CONTROL_SCENE_DIRECTORY := "res://Scenes/UI/Controls/"
const ACTION_MARKERS := {
	"left": ["A"],
	"right": ["D"],
	"jump": ["W", "Space", "Control2"],
	"down": ["S"],
	"interact": ["E", "Control"],
	"shoot": ["Shoot"],
	"bullet_time": ["Right Click"],
	"menu": ["Esc"],
	"restart": ["R"],
}
const MOUSE_SCENES := {
	MOUSE_BUTTON_LEFT: "LeftClick",
	MOUSE_BUTTON_RIGHT: "RightClick",
	MOUSE_BUTTON_MIDDLE: "MiddleClick",
	MOUSE_BUTTON_WHEEL_UP: "WheelUp",
	MOUSE_BUTTON_WHEEL_DOWN: "WheelDown",
}
const CONTROLLER_BUTTON_SCENES := {
	0: "ControllerA",
	1: "ControllerB",
	2: "ControllerX",
	3: "ControllerY",
	4: "ControllerView",
	5: "ControllerHome",
	6: "ControllerMenu",
	7: "ControllerL3",
	8: "ControllerR3",
	9: "ControllerL1",
	10: "ControllerR1",
	11: "ControllerDPadUp",
	12: "ControllerDPadDown",
	13: "ControllerDPadLeft",
	14: "ControllerDPadRight",
	15: "ControllerShare",
	16: "ControllerL4",
	17: "ControllerR4",
	18: "ControllerL5",
	19: "ControllerR5",
}
const KEY_SCENE_ALIASES := {
	"Escape": "Escape",
	"Tab": "Tab",
	"Backtab": "Tab",
	"Backspace": "Backspace",
	"Enter": "Enter",
	"Kp Enter": "Enter",
	"Insert": "Insert",
	"Delete": "Delete",
	"Pause": "Pause",
	"Print": "Print",
	"Print Screen": "Print",
	"Home": "Home",
	"End": "End",
	"Left": "Left",
	"Up": "Up",
	"Right": "Right",
	"Down": "Down",
	"PageUp": "PageUp",
	"Page Up": "PageUp",
	"PageDown": "PageDown",
	"Page Down": "PageDown",
	"Shift": "Shift",
	"Ctrl": "Ctrl",
	"Control": "Ctrl",
	"Alt": "Alt",
	"Space": "Space",
	"'": "Apostrophe",
	"Apostrophe": "Apostrophe",
	"\\": "BackSlash",
	"Backslash": "BackSlash",
	"[": "BracketLeft",
	"BracketLeft": "BracketLeft",
	"]": "BracketRight",
	"BracketRight": "BracketRight",
	",": "Comma",
	"Comma": "Comma",
	"=": "Equal",
	"Equal": "Equal",
	"-": "Minus",
	"Minus": "Minus",
	".": "Period",
	"Period": "Period",
	"?": "QuestionMark",
	"/": "Slash",
	"Slash": "Slash",
	";": "SemiColon",
	"Semicolon": "SemiColon",
	"`": "Tilde",
	"~": "Tilde",
	"QuoteLeft": "Tilde",
}

var _action_positions: Dictionary = {}
var _prompt_nodes: Dictionary = {}
var _cycle_indices: Dictionary = {}
var _scene_cache: Dictionary = {}
var _animation_positions: Dictionary = {}
var _animation_cycle_started: Dictionary = {}
var _animation_reversing: Dictionary = {}
var _fallback_cycle_elapsed: Dictionary = {}
var _display_device := SettingsManager.INPUT_DEVICE_KEYBOARD

func _ready() -> void:
	_prepare_markers()
	_display_device = SettingsManager.last_input_device
	SettingsManager.input_bindings_changed.connect(_on_input_bindings_changed)
	SettingsManager.input_device_changed.connect(_on_input_device_changed)
	_refresh_all_prompts()

func _process(delta: float) -> void:
	for action_value in ACTION_MARKERS:
		var action := String(action_value)
		var events := _get_display_events(action)
		if events.size() < 2:
			_animation_positions.erase(action)
			_animation_cycle_started.erase(action)
			_animation_reversing.erase(action)
			_fallback_cycle_elapsed.erase(action)
			continue
		var prompt := _prompt_nodes.get(action) as Control
		var animation_player: AnimationPlayer = null
		if prompt != null:
			animation_player = prompt.get_node_or_null(NodePath("AnimationPlayer")) as AnimationPlayer
		if animation_player != null and animation_player.current_animation == &"Press":
			var current_position := animation_player.current_animation_position
			var previous_position := float(_animation_positions.get(action, current_position))
			_animation_positions[action] = current_position
			_fallback_cycle_elapsed.erase(action)
			if current_position > previous_position + 0.001:
				if bool(_animation_reversing.get(action, false)):
					_advance_binding(action, events)
				else:
					_animation_cycle_started[action] = true
			elif current_position + 0.001 < previous_position and bool(_animation_cycle_started.get(action, false)):
				_animation_reversing[action] = true
			continue

		var elapsed := float(_fallback_cycle_elapsed.get(action, 0.0)) + delta
		if elapsed >= fallback_cycle_seconds:
			_fallback_cycle_elapsed[action] = fmod(elapsed, fallback_cycle_seconds)
			_advance_binding(action, events)
		else:
			_fallback_cycle_elapsed[action] = elapsed

func _advance_binding(action: String, events: Array[InputEvent]) -> void:
	_cycle_indices[action] = (int(_cycle_indices.get(action, 0)) + 1) % events.size()
	_refresh_prompt(action, events)

func _prepare_markers() -> void:
	for action_value in ACTION_MARKERS:
		var action := String(action_value)
		var marker_positions: Array[Vector2] = []
		var marker_names: Array = ACTION_MARKERS[action]
		for marker_name_value in marker_names:
			var marker := get_node_or_null(NodePath(String(marker_name_value))) as Control
			if marker == null:
				continue
			marker_positions.append(marker.position)
			marker.visible = false
			marker.process_mode = Node.PROCESS_MODE_DISABLED
		if marker_positions.is_empty():
			push_warning("Full Controls has no marker node for the '%s' action." % action)
			continue
		var combined_position := Vector2.ZERO
		for marker_position in marker_positions:
			combined_position += marker_position
		_action_positions[action] = combined_position / marker_positions.size()

func _on_input_bindings_changed() -> void:
	_cycle_indices.clear()
	_animation_positions.clear()
	_animation_cycle_started.clear()
	_animation_reversing.clear()
	_fallback_cycle_elapsed.clear()
	_refresh_all_prompts()

func _on_input_device_changed(device_type: String) -> void:
	_display_device = device_type
	_cycle_indices.clear()
	_animation_positions.clear()
	_animation_cycle_started.clear()
	_animation_reversing.clear()
	_fallback_cycle_elapsed.clear()
	_refresh_all_prompts()

func _refresh_all_prompts() -> void:
	for action_value in ACTION_MARKERS:
		var action := String(action_value)
		_refresh_prompt(action, _get_display_events(action))

func _refresh_prompt(action: String, events: Array[InputEvent]) -> void:
	if _prompt_nodes.has(action):
		var old_prompt := _prompt_nodes[action] as Node
		if is_instance_valid(old_prompt):
			old_prompt.queue_free()
		_prompt_nodes.erase(action)

	if not _action_positions.has(action):
		return
	var event: InputEvent = events[int(_cycle_indices.get(action, 0)) % events.size()] if not events.is_empty() else null
	var scene_name := get_scene_name(event)
	var prompt: Control = _instantiate_prompt(scene_name, get_event_text(event))
	prompt.position = Vector2(_action_positions[action])
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt)
	_prompt_nodes[action] = prompt
	var animation_player := prompt.get_node_or_null(NodePath("AnimationPlayer")) as AnimationPlayer
	if animation_player != null and animation_player.has_animation(&"Press"):
		animation_player.play(&"Press")
		_animation_positions[action] = animation_player.current_animation_position
		_animation_cycle_started[action] = false
		_animation_reversing[action] = false
	else:
		_animation_positions.erase(action)
		_animation_cycle_started.erase(action)
		_animation_reversing.erase(action)
	_fallback_cycle_elapsed[action] = 0.0

func _get_display_events(action: String) -> Array[InputEvent]:
	var matches: Array[InputEvent] = []
	if not InputMap.has_action(action):
		return matches
	for event in InputMap.action_get_events(action):
		if _display_device == SettingsManager.INPUT_DEVICE_CONTROLLER:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				matches.append(event)
		elif event is InputEventKey or event is InputEventMouseButton:
			matches.append(event)
	return matches

func _instantiate_prompt(scene_name: String, fallback_text: String) -> Control:
	if not scene_name.is_empty():
		var scene_path := CONTROL_SCENE_DIRECTORY + scene_name + ".tscn"
		var packed_scene := _scene_cache.get(scene_path) as PackedScene
		if packed_scene == null and ResourceLoader.exists(scene_path):
			packed_scene = load(scene_path) as PackedScene
			_scene_cache[scene_path] = packed_scene
		if packed_scene != null:
			return packed_scene.instantiate() as Control

	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.position = Vector2(-90.0, -30.0)
	label.size = Vector2(180.0, 60.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.text = fallback_text
	holder.add_child(label)
	return holder

static func get_scene_name(event: InputEvent) -> String:
	if event == null:
		return ""
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		var key_text := OS.get_keycode_string(code)
		if key_text.length() == 1:
			var character := key_text.unicode_at(0)
			if (character >= 48 and character <= 57) or (character >= 65 and character <= 90):
				return key_text
		return String(KEY_SCENE_ALIASES.get(key_text, ""))
	if event is InputEventMouseButton:
		return String(MOUSE_SCENES.get((event as InputEventMouseButton).button_index, ""))
	if event is InputEventJoypadButton:
		return String(CONTROLLER_BUTTON_SCENES.get((event as InputEventJoypadButton).button_index, ""))
	if event is InputEventJoypadMotion:
		return get_controller_axis_scene(event as InputEventJoypadMotion)
	return ""

static func get_controller_axis_scene(event: InputEventJoypadMotion) -> String:
	var positive := event.axis_value > 0.0
	match event.axis:
		0: return "ControllerLStickRight" if positive else "ControllerLStickLeft"
		1: return "ControllerLStickDown" if positive else "ControllerLStickUp"
		2: return "ControllerRStickRight" if positive else "ControllerRStickLeft"
		3: return "ControllerRStickDown" if positive else "ControllerRStickUp"
		4: return "ControllerL2"
		5: return "ControllerR2"
	return ""

static func get_event_text(event: InputEvent) -> String:
	if event == null:
		return "Unbound"
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		return SettingsManager.get_mouse_button_name((event as InputEventMouseButton).button_index)
	if event is InputEventJoypadButton:
		return SettingsManager.get_controller_button_name((event as InputEventJoypadButton).button_index)
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return SettingsManager.get_controller_axis_name(motion.axis)
	return event.as_text()

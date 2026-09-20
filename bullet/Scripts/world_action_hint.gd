extends Node2D

const FULL_CONTROLS_SCRIPT := preload("res://Scripts/full_controls.gd")
const CONTROL_SCENE_DIRECTORY := "res://Scenes/UI/Controls/"

@export var action := "interact"
@export var fuse_path: NodePath
@export var trigger_cell := Vector2i.ZERO
@export var prompt_scale := Vector2.ONE
@export var hide_after_ignition := true

var fuse: Node2D
var prompt: Control
var binding_events: Array[InputEvent] = []
var binding_index := 0
var animation_position := 0.0
var animation_cycle_started := false
var animation_reversing := false
var fallback_cycle_elapsed := 0.0

func _ready() -> void:
	prompt = get_node_or_null("Prompt") as Control
	visible = false
	set_process(false)
	SettingsManager.input_bindings_changed.connect(_refresh_prompt)
	SettingsManager.input_device_changed.connect(_on_input_device_changed)
	_refresh_prompt()
	call_deferred("_resolve_trigger")

func _process(delta: float) -> void:
	_update_prompt_cycle(delta)
	if not is_instance_valid(fuse):
		return
	var trigger_areas: Dictionary = fuse.get("trigger_areas")
	if not trigger_areas.has(trigger_cell):
		visible = false
		return
	var trigger_area := trigger_areas[trigger_cell] as Area2D
	if not is_instance_valid(trigger_area):
		visible = false
		return
	visible = fuse.is_visible_in_tree() and (not hide_after_ignition or not bool(fuse.get("has_ignited")))

func _resolve_trigger() -> void:
	fuse = get_node_or_null(fuse_path) as Node2D
	if fuse == null:
		push_warning("World action hint could not find fuse at %s." % fuse_path)
		visible = false
		return
	set_process(true)

func _on_input_device_changed(_device_type: String) -> void:
	_refresh_prompt()

func _refresh_prompt() -> void:
	binding_events = _get_action_events()
	binding_index = 0
	_replace_prompt()

func _get_action_events() -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	if not InputMap.has_action(action):
		return events
	for event in InputMap.action_get_events(action):
		if SettingsManager.last_input_device == SettingsManager.INPUT_DEVICE_CONTROLLER:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				events.append(event)
		elif event is InputEventKey or event is InputEventMouseButton:
			events.append(event)
	return events

func _replace_prompt() -> void:
	if is_instance_valid(prompt):
		remove_child(prompt)
		prompt.queue_free()
	var event: InputEvent = binding_events[binding_index % binding_events.size()] if not binding_events.is_empty() else null
	var scene_name := FULL_CONTROLS_SCRIPT.get_scene_name(event)
	prompt = _instantiate_prompt(scene_name, FULL_CONTROLS_SCRIPT.get_event_text(event))
	prompt.scale = prompt_scale
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.name = "Prompt"
	add_child(prompt)
	var animation_player := prompt.get_node_or_null(NodePath("AnimationPlayer")) as AnimationPlayer
	if animation_player != null and animation_player.has_animation(&"Press"):
		animation_player.play(&"Press")
		animation_position = animation_player.current_animation_position
	else:
		animation_position = 0.0
	animation_cycle_started = false
	animation_reversing = false
	fallback_cycle_elapsed = 0.0

func _instantiate_prompt(scene_name: String, fallback_text: String) -> Control:
	if not scene_name.is_empty():
		var scene_path := CONTROL_SCENE_DIRECTORY + scene_name + ".tscn"
		if ResourceLoader.exists(scene_path):
			var packed_scene := load(scene_path) as PackedScene
			if packed_scene != null:
				return packed_scene.instantiate() as Control
	var holder := Control.new()
	var label := Label.new()
	label.position = Vector2(-16.0, -8.0)
	label.size = Vector2(32.0, 16.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 7)
	label.text = fallback_text
	holder.add_child(label)
	return holder

func _update_prompt_cycle(delta: float) -> void:
	if binding_events.size() < 2 or not is_instance_valid(prompt):
		return
	var animation_player := prompt.get_node_or_null(NodePath("AnimationPlayer")) as AnimationPlayer
	if animation_player != null and animation_player.current_animation == &"Press":
		var current_position := animation_player.current_animation_position
		if current_position > animation_position + 0.001:
			if animation_reversing:
				_advance_binding()
				return
			animation_cycle_started = true
		elif current_position + 0.001 < animation_position and animation_cycle_started:
			animation_reversing = true
		animation_position = current_position
		return
	fallback_cycle_elapsed += delta
	if fallback_cycle_elapsed >= 1.75:
		_advance_binding()

func _advance_binding() -> void:
	binding_index = (binding_index + 1) % binding_events.size()
	_replace_prompt()

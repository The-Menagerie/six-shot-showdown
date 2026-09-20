extends Label

const FULL_CONTROLS_SCRIPT := preload("res://Scripts/full_controls.gd")
const CONTROL_SCENE_DIRECTORY := "res://Scenes/UI/Controls/"
const ACT_1_LEVEL_DIRECTORY := "res://Scenes/Levels/Act 1/"

@export_range(0.05, 1.0, 0.05) var fade_duration: float = 0.25
@export_range(0.0, 3.0, 0.05) var show_delay: float = 0.35
@export var follow_offset: Vector2 = Vector2(0.0, -52.0)
@export var key_gap: float = 8.0
@export var key_visual_width: float = 22.0
@export var key_horizontal_offset: float = 0.0
@export var key_vertical_offset: float = 10.0

var fade_tween: Tween
var delay_timer: SceneTreeTimer
var is_allowed_in_level := false
var is_out_of_ammo := false
var player: Node2D
var key_hint: Control
var key_hint_scale := Vector2.ONE
var binding_events: Array[InputEvent] = []
var binding_index := 0
var animation_position := 0.0
var animation_cycle_started := false
var animation_reversing := false
var fallback_cycle_elapsed := 0.0
@onready var key_hint_marker: Control = $R

func _ready() -> void:
	modulate.a = 0.0
	hide()
	key_hint_scale = key_hint_marker.scale
	key_hint_marker.visible = false
	key_hint_marker.process_mode = Node.PROCESS_MODE_DISABLED
	SettingsManager.input_bindings_changed.connect(_refresh_restart_prompt)
	SettingsManager.input_device_changed.connect(_on_input_device_changed)
	_refresh_restart_prompt()
	BulletBus.out_of_ammo_changed.connect(_on_out_of_ammo_changed)
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_signal("level_changed"):
		game_manager.level_changed.connect(_on_level_changed)
		_on_level_changed(game_manager.current_level.scene_file_path)
	set_process(true)

func _process(delta: float) -> void:
	_update_prompt_cycle(delta)
	if not visible:
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		if not is_instance_valid(player):
			return

	var label_size := size
	if label_size == Vector2.ZERO:
		label_size = get_combined_minimum_size()

	var total_width := label_size.x + key_visual_width + key_gap
	var screen_position := player.get_global_transform_with_canvas().origin + follow_offset
	position = Vector2(
		screen_position.x - (total_width * 0.5) + key_visual_width + key_gap,
		screen_position.y - label_size.y
	)

	if is_instance_valid(key_hint):
		key_hint.position = Vector2(
			-key_visual_width - key_gap + key_horizontal_offset,
			((label_size.y - key_visual_width) * 0.5) + key_vertical_offset
		)

func _on_input_device_changed(_device_type: String) -> void:
	_refresh_restart_prompt()

func _refresh_restart_prompt() -> void:
	binding_events = _get_restart_events()
	binding_index = 0
	_replace_key_hint()

func _get_restart_events() -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	if not InputMap.has_action("restart"):
		return events
	for event in InputMap.action_get_events("restart"):
		if SettingsManager.last_input_device == SettingsManager.INPUT_DEVICE_CONTROLLER:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				events.append(event)
		elif event is InputEventKey or event is InputEventMouseButton:
			events.append(event)
	return events

func _replace_key_hint() -> void:
	if is_instance_valid(key_hint):
		key_hint.queue_free()
	var event: InputEvent = binding_events[binding_index % binding_events.size()] if not binding_events.is_empty() else null
	var scene_name := FULL_CONTROLS_SCRIPT.get_scene_name(event)
	key_hint = _instantiate_key_hint(scene_name, FULL_CONTROLS_SCRIPT.get_event_text(event))
	key_hint.scale = key_hint_scale
	key_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(key_hint)
	var animation_player := key_hint.get_node_or_null(NodePath("AnimationPlayer")) as AnimationPlayer
	if animation_player != null and animation_player.has_animation(&"Press"):
		animation_player.play(&"Press")
		animation_position = animation_player.current_animation_position
	else:
		animation_position = 0.0
	animation_cycle_started = false
	animation_reversing = false
	fallback_cycle_elapsed = 0.0

func _instantiate_key_hint(scene_name: String, fallback_text: String) -> Control:
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
	if binding_events.size() < 2 or not is_instance_valid(key_hint):
		return
	var animation_player := key_hint.get_node_or_null(NodePath("AnimationPlayer")) as AnimationPlayer
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
	_replace_key_hint()

func _on_out_of_ammo_changed(is_out_of_ammo: bool) -> void:
	self.is_out_of_ammo = is_out_of_ammo
	if not is_allowed_in_level:
		_hide_immediately()
		return

	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	delay_timer = null

	if is_out_of_ammo:
		if is_zero_approx(show_delay):
			_show_hint()
			return

		delay_timer = get_tree().create_timer(show_delay)
		await delay_timer.timeout
		if self.is_out_of_ammo and is_allowed_in_level:
			_show_hint()
		return

	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.finished.connect(hide)

func _on_level_changed(level_path: String) -> void:
	player = null
	is_allowed_in_level = level_path.begins_with(ACT_1_LEVEL_DIRECTORY)
	if not is_allowed_in_level:
		_hide_immediately()

func _hide_immediately() -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	delay_timer = null
	modulate.a = 0.0
	hide()

func _show_hint() -> void:
	if not is_allowed_in_level:
		return
	show()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)

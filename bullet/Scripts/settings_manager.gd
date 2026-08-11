extends Node

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "gameplay"
const SKIP_TUTORIAL_KEY := "skip_tutorial"
const AIM_SPEED_KEY := "aim_speed"
const CURSOR_HOTSPOT := Vector2(10, 10)
const UI_TEXT_SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.85)
const UI_TEXT_SHADOW_OFFSET := Vector2i(3, 3)
const DEFAULT_AIM_SPEED := 900.0
const MIN_AIM_SPEED := 150.0
const MAX_AIM_SPEED := 2200.0

@export var reticle_edge_padding : float = 4.0

var reticle = load("res://Assets/Tilesets/StrangeCowboy/Player/reticle_norm.png")
var reticle_clicked = load("res://Assets/Tilesets/StrangeCowboy/Player/reticle_clicked.png")

var skip_tutorial := false
var aim_speed := DEFAULT_AIM_SPEED

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_custom_cursor()
	var tree := get_tree()
	if tree != null and not tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.connect(_on_tree_node_added)
	call_deferred("_apply_text_shadows_to_existing_controls")

func _process(delta: float) -> void:
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

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_apply_cursor_texture(reticle_clicked if event.pressed else reticle)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return

	if event.is_echo():
		return

	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		_click_hovered_ui_control()

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

func _click_hovered_ui_control() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return

	var hovered_control := viewport.gui_get_hovered_control()
	if hovered_control == null:
		return
	if not _should_treat_accept_as_click(hovered_control):
		return

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
	if get_tree() != null and get_tree().paused:
		return true

	var current_scene := get_tree().current_scene
	if current_scene == null or current_scene.scene_file_path.is_empty():
		return false

	var scene_path := current_scene.scene_file_path
	return scene_path.begins_with("res://Scenes/UI/MainMenu/") or scene_path == "res://Scenes/Cutscene.tscn"

func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		skip_tutorial = false
		aim_speed = DEFAULT_AIM_SPEED
		return

	skip_tutorial = bool(config.get_value(SETTINGS_SECTION, SKIP_TUTORIAL_KEY, false))
	aim_speed = clampf(
		float(config.get_value(SETTINGS_SECTION, AIM_SPEED_KEY, DEFAULT_AIM_SPEED)),
		MIN_AIM_SPEED,
		MAX_AIM_SPEED
	)

func set_skip_tutorial(enabled: bool) -> void:
	if skip_tutorial == enabled:
		return

	skip_tutorial = enabled
	save_settings()

func set_aim_speed(value: float) -> void:
	var clamped_value := clampf(value, MIN_AIM_SPEED, MAX_AIM_SPEED)
	if is_equal_approx(aim_speed, clamped_value):
		return

	aim_speed = clamped_value
	save_settings()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, SKIP_TUTORIAL_KEY, skip_tutorial)
	config.set_value(SETTINGS_SECTION, AIM_SPEED_KEY, aim_speed)
	config.save(SETTINGS_PATH)

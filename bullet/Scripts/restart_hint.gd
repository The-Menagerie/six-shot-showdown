extends Label

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
@onready var key_hint: Control = $R

func _ready() -> void:
	modulate.a = 0.0
	hide()
	BulletBus.out_of_ammo_changed.connect(_on_out_of_ammo_changed)
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_signal("level_changed"):
		game_manager.level_changed.connect(_on_level_changed)
		_on_level_changed(game_manager.current_level.scene_file_path)
	set_process(true)

func _process(_delta: float) -> void:
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
		if self.is_out_of_ammo:
			_show_hint()
		return

	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.finished.connect(hide)

func _on_level_changed(level_path: String) -> void:
	player = null
	var level_name := level_path.get_file()
	is_allowed_in_level = not level_name.begins_with("tut_")
	if not is_allowed_in_level:
		_hide_immediately()

func _hide_immediately() -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	delay_timer = null
	modulate.a = 0.0
	hide()

func _show_hint() -> void:
	show()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)

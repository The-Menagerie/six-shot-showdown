extends Node2D

signal level_changed(level_path: String)

@export var current_level: Node
@export var anim_player: Node
@export var tutorial_level_scene: PackedScene
@export var first_level_scene: PackedScene
@export_range(0.05, 1.0, 0.05) var bullet_time_scale: float = 0.35
@export_range(0.05, 1.0, 0.05) var bullet_time_music_scale: float = 0.75
@export_range(0.05, 1.0, 0.05) var bullet_time_sfx_scale: float = 0.35
@export_range(0.0, 1.0, 0.05) var bullet_time_overlay_intensity: float = 0.7
@export_range(0.5, 1.5, 0.05) var bullet_time_overlay_contrast: float = 1.0
@export_range(0.0, 1.0, 0.05) var bullet_time_overlay_fade_duration: float = 0.18
@export_range(0.0, 3.0, 0.05) var level_fade_in_duration: float = 1.75
@export var transition_text_start_scale: Vector2 = Vector2(2.0, 2.0)
@export var transition_text_end_scale: Vector2 = Vector2(3.0, 3.0)

var is_bullet_time_active := false
var is_level_reset_queued := false
var is_level_transition_active := false
var bullet_time_overlay_tween: Tween
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var bullet_time_overlay: ColorRect = $CanvasLayer/BulletTimeOverlay
@onready var transition_overlay: ColorRect = $CanvasLayer/TransitionOverlay
@onready var transition_text: Label = $CanvasLayer/TransitionOverlay/TransitionText
#@onready var score_label: Label = $CanvasLayer/ScoreLabel

#func _ready():
	#_update_score_label()

func _ready():
	Engine.time_scale = 1.0
	_apply_initial_level_selection()
	if is_instance_valid(music_player):
		music_player.finished.connect(_on_music_finished)
		if not music_player.playing:
			music_player.play()
	_configure_bullet_time_overlay()
	_apply_audio_pitch_scale_to_subtree(self)
	_emit_level_changed()
	call_deferred("_play_initial_level_intro")

func _process(_delta):
	_update_bullet_time()

func _apply_initial_level_selection() -> void:
	if current_level == null:
		return

	if SettingsManager.skip_tutorial:
		if first_level_scene != null and current_level.scene_file_path.get_file() != first_level_scene.resource_path.get_file():
			change_level(first_level_scene)
			return
	elif tutorial_level_scene != null and current_level.scene_file_path.get_file() != tutorial_level_scene.resource_path.get_file():
		change_level(tutorial_level_scene)

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if is_level_transition_active or is_level_reset_queued:
		return
	if event.is_action_pressed("restart") and not event.is_echo():
		reset_current_level()
		get_viewport().set_input_as_handled()

func change_level(level: PackedScene) -> void:
	var new_level = level.instantiate()
	call_deferred("add_child",new_level)
	current_level.queue_free()
	current_level = new_level
	call_deferred("_emit_level_changed")

func transition_to_level(level: PackedScene, fade_out_duration: float) -> void:
	if is_level_transition_active:
		return

	is_level_transition_active = true
	call_deferred("_run_level_transition", level, fade_out_duration)

func reset_current_level() -> void:
	if is_level_reset_queued:
		return
	if current_level == null:
		return
	if current_level.scene_file_path.is_empty():
		return

	ScoreBus.register_level_reset()
	is_level_reset_queued = true
	call_deferred("_deferred_reset_current_level")

func _deferred_reset_current_level() -> void:
	if current_level == null:
		is_level_reset_queued = false
		return

	var level_scene := load(current_level.scene_file_path) as PackedScene
	if level_scene == null:
		is_level_reset_queued = false
		return

	var new_level := level_scene.instantiate()
	add_child(new_level)
	current_level.queue_free()
	current_level = new_level
	is_level_reset_queued = false
	_apply_audio_pitch_scale_to_subtree(new_level)
	_emit_level_changed()


func _update_bullet_time():
	var should_enable_bullet_time = Input.is_action_pressed("bullet_time")
	if should_enable_bullet_time == is_bullet_time_active:
		return

	is_bullet_time_active = should_enable_bullet_time
	Engine.time_scale = bullet_time_scale if is_bullet_time_active else 1.0
	_apply_audio_pitch_scale_to_subtree(self)
	_update_bullet_time_overlay()


func _exit_tree():
	Engine.time_scale = 1.0
	is_bullet_time_active = false
	_apply_audio_pitch_scale_to_subtree(self)
	_set_bullet_time_overlay_intensity(0.0)

func _emit_level_changed() -> void:
	if current_level == null:
		return

	_apply_audio_pitch_scale_to_subtree(current_level)
	level_changed.emit(current_level.scene_file_path)

func configure_audio_player_for_bullet_time(audio_player: AudioStreamPlayer) -> void:
	if not is_instance_valid(audio_player):
		return

	audio_player.pitch_scale = _get_pitch_scale_for_bus(audio_player.bus)

func _apply_audio_pitch_scale_to_subtree(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return

	if root is AudioStreamPlayer:
		configure_audio_player_for_bullet_time(root as AudioStreamPlayer)

	for child in root.get_children():
		_apply_audio_pitch_scale_to_subtree(child)

func _get_pitch_scale_for_bus(bus_name: StringName) -> float:
	if not is_bullet_time_active:
		return 1.0

	if bus_name == &"music":
		return bullet_time_music_scale
	if bus_name == &"sfx":
		return bullet_time_sfx_scale
	return 1.0

func _configure_bullet_time_overlay() -> void:
	if not is_instance_valid(bullet_time_overlay):
		return

	var overlay_material := bullet_time_overlay.material as ShaderMaterial
	if overlay_material == null:
		return

	overlay_material.set_shader_parameter("contrast", bullet_time_overlay_contrast)
	overlay_material.set_shader_parameter("intensity", 0.0)

func _update_bullet_time_overlay() -> void:
	if not is_instance_valid(bullet_time_overlay):
		return

	var target_intensity := bullet_time_overlay_intensity if is_bullet_time_active else 0.0
	if is_instance_valid(bullet_time_overlay_tween):
		bullet_time_overlay_tween.kill()

	if is_zero_approx(bullet_time_overlay_fade_duration):
		_set_bullet_time_overlay_intensity(target_intensity)
		return

	bullet_time_overlay_tween = create_tween()
	bullet_time_overlay_tween.tween_method(_set_bullet_time_overlay_intensity, _get_bullet_time_overlay_intensity(), target_intensity, bullet_time_overlay_fade_duration)

func _set_bullet_time_overlay_intensity(value: float) -> void:
	if not is_instance_valid(bullet_time_overlay):
		return

	var overlay_material := bullet_time_overlay.material as ShaderMaterial
	if overlay_material == null:
		return

	overlay_material.set_shader_parameter("intensity", value)

func _get_bullet_time_overlay_intensity() -> float:
	if not is_instance_valid(bullet_time_overlay):
		return 0.0

	var overlay_material := bullet_time_overlay.material as ShaderMaterial
	if overlay_material == null:
		return 0.0

	return float(overlay_material.get_shader_parameter("intensity"))

func _on_music_finished() -> void:
	if is_instance_valid(music_player):
		music_player.play()

func _run_level_transition(level: PackedScene, fade_out_duration: float) -> void:
	if level == null:
		is_level_transition_active = false
		return

	var fade_out_time: float = max(fade_out_duration, 0.01)
	if is_instance_valid(transition_overlay):
		transition_overlay.show()
		transition_overlay.modulate.a = 0.0
		var fade_out_tween: Tween = create_tween()
		fade_out_tween.tween_property(transition_overlay, "modulate:a", 1.0, fade_out_time)
		await fade_out_tween.finished
	elif fade_out_duration > 0.0:
		await get_tree().create_timer(fade_out_duration).timeout

	change_level(level)
	await get_tree().process_frame

	await _play_transition_fade_in(level.resource_path)

	is_level_transition_active = false

func _update_transition_text() -> void:
	if not is_instance_valid(transition_text) or current_level == null:
		return

	_update_transition_text_for_path(current_level.scene_file_path)

func _update_transition_text_for_path(level_path: String) -> void:
	if not is_instance_valid(transition_text):
		return

	var level_name: String = level_path.get_file()
	if level_name == "tut_01.tscn":
		transition_text.text = "Tutorial 1"
		transition_text.show()
		return
	if level_name == "tut_02.tscn":
		transition_text.text = "Tutorial 2"
		transition_text.show()
		return
	if level_name == "tut_03.tscn":
		transition_text.text = "Tutorial 3"
		transition_text.show()
		return
	if not level_name.begins_with("lvl_"):
		transition_text.hide()
		return

	var level_number_text: String = level_name.trim_prefix("lvl_").trim_suffix(".tscn")
	var level_number: int = int(level_number_text)
	var minutes_until_showdown: int = 13 - level_number
	if minutes_until_showdown < 1:
		transition_text.hide()
		return

	var minute_label: String = "Minute" if minutes_until_showdown == 1 else "Minutes"
	transition_text.text = "%d %s til Showdown" % [minutes_until_showdown, minute_label]
	transition_text.show()

func _play_initial_level_intro() -> void:
	if current_level == null:
		return
	if is_level_transition_active:
		return

	await _play_transition_fade_in(current_level.scene_file_path)

func _play_transition_fade_in(level_path: String) -> void:
	if not is_instance_valid(transition_overlay):
		return

	transition_overlay.show()
	_update_transition_text_for_path(level_path)
	transition_overlay.modulate.a = 1.0
	if is_instance_valid(transition_text) and transition_text.visible:
		var text_size: Vector2 = transition_text.size
		if text_size == Vector2.ZERO:
			text_size = transition_text.get_combined_minimum_size()
		transition_text.pivot_offset = text_size * 0.5
		transition_text.scale = transition_text_start_scale

	var fade_in_tween: Tween = create_tween()
	if is_instance_valid(transition_text) and transition_text.visible:
		fade_in_tween.set_parallel(true)
		fade_in_tween.tween_property(transition_text, "scale", transition_text_end_scale, level_fade_in_duration)
	fade_in_tween.tween_property(transition_overlay, "modulate:a", 0.0, level_fade_in_duration)
	await fade_in_tween.finished
	transition_overlay.hide()
	if is_instance_valid(transition_text):
		transition_text.hide()

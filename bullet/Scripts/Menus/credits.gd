extends Control

const SCORE_SCREEN = preload("res://Scenes/UI/temp_score_scene.tscn")
const MENU_MUSIC = preload("res://Assets/Music/CowboyMenuSong.mp3")

@export var fade_duration: float = 0.6
@export var line_hold_duration: float = 2.5
@export var opened_from_menu := false

var action_in_progress := false
var credit_lines: Array[String] = []
var credit_tween: Tween
var line_labels: Array[Label] = []
var line_container: VBoxContainer

@onready var names: Label = $CanvasLayer/Credits/Names
@onready var skip_button: Button = $CanvasLayer/Skip

func _ready() -> void:
	if opened_from_menu:
		skip_button.text = "Menu"
		MusicManager.play_music(MENU_MUSIC, -10.0)
	# Use the text authored directly in the scene's Names label.
	line_container = VBoxContainer.new()
	line_container.name = "RevealedLines"
	line_container.add_theme_constant_override("separation", 4)
	$CanvasLayer/Credits.add_child(line_container)
	line_container.anchor_left = names.anchor_left
	line_container.anchor_top = names.anchor_top
	line_container.anchor_right = names.anchor_right
	line_container.anchor_bottom = names.anchor_bottom
	line_container.offset_left = names.offset_left
	line_container.offset_top = names.offset_top
	line_container.offset_right = names.offset_right
	line_container.offset_bottom = names.offset_bottom
	for line in names.text.split("\n"):
		var trimmed_line := line.strip_edges()
		if trimmed_line.is_empty():
			var spacer := Control.new()
			spacer.custom_minimum_size.y = 12.0
			line_container.add_child(spacer)
		else:
			_add_credit_line(trimmed_line)
	var thanks: Label = $CanvasLayer/Credits/Thanks
	if not thanks.text.is_empty():
		_add_credit_line(thanks.text)
	thanks.hide()
	names.hide()
	skip_button.grab_focus()
	call_deferred("_fit_credit_lines")
	credit_tween = create_tween()
	for label in line_labels:
		credit_tween.tween_property(label, "modulate:a", 1.0, fade_duration)
		credit_tween.tween_interval(line_hold_duration)
	credit_tween.tween_callback(_finish_credits)

func _add_credit_line(line: String) -> void:
	credit_lines.append(line)
	var label := Label.new()
	label.text = line
	label.horizontal_alignment = names.horizontal_alignment
	label.autowrap_mode = names.autowrap_mode
	label.add_theme_font_override("font", names.get_theme_font("font"))
	label.add_theme_font_size_override("font_size", names.get_theme_font_size("font_size"))
	label.modulate.a = 0.0
	line_container.add_child(label)
	line_labels.append(label)

func _fit_credit_lines() -> void:
	await get_tree().process_frame
	var area_height: float = $CanvasLayer/Credits.size.y * (names.anchor_bottom - names.anchor_top) + names.offset_bottom - names.offset_top
	var font_size := names.get_theme_font_size("font_size")
	while font_size > 16 and line_container.get_combined_minimum_size().y > area_height:
		font_size -= 1
		for label in line_labels:
			label.add_theme_font_size_override("font_size", font_size)
		line_container.update_minimum_size()

func _on_skip_pressed() -> void:
	if action_in_progress or (not opened_from_menu and get_parent().is_level_transition_active):
		return
	action_in_progress = true
	if is_instance_valid(credit_tween):
		credit_tween.kill()
	$WoodenBlock.play()
	await $WoodenBlock.finished
	if opened_from_menu:
		get_tree().change_scene_to_file("res://Scenes/UI/MainMenu/menu.tscn")
		return
	get_parent().transition_to_level(SCORE_SCREEN, 0.3)

func _finish_credits() -> void:
	if opened_from_menu or action_in_progress:
		return
	skip_button.text = "Continue"

func _unhandled_input(event: InputEvent) -> void:
	if opened_from_menu and SettingsManager.is_menu_back_event(event):
		get_viewport().set_input_as_handled()
		_on_skip_pressed()

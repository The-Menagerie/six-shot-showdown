extends Control

const ACT_LEADERBOARD = preload("res://Scenes/UI/act_score_screen.tscn")
const BUTTON_TEXT_SHADOW = preload("res://Scripts/UI/button_text_shadow.gd")

var selected_page := 0
var act_screen: Control

@onready var summary_layer: CanvasLayer = $CanvasLayer
@onready var summary_score: Label = $CanvasLayer/Panel/Container/Score

func _on_left_pressed() -> void:
	_change_page(-1)

func _on_right_pressed() -> void:
	_change_page(1)

func _change_page(direction: int) -> void:
	if summary_score.menu_action_in_progress or (act_screen != null and act_screen.action_in_progress):
		return
	$WoodenBlock.play()
	selected_page = posmod(selected_page + direction, 4)
	if act_screen != null:
		act_screen.set_process_unhandled_input(false)
		act_screen.get_node("CanvasLayer").hide()
		act_screen.queue_free()
		act_screen = null
	if selected_page == 0:
		summary_layer.show()
		summary_score.set_process_unhandled_input(true)
		return
	summary_layer.hide()
	summary_score.set_process_unhandled_input(false)
	act_screen = ACT_LEADERBOARD.instantiate()
	act_screen.selected_act = selected_page
	act_screen.get_node("CanvasLayer/Panel/Container/Replay").hide()
	act_screen.get_node("CanvasLayer/Panel/Container/HSeparator2").hide()
	act_screen.get_node("CanvasLayer/Panel/Container/Back").text = "Back to Main Menu"
	act_screen.back_requested.connect(_on_back_requested)
	add_child(act_screen)
	act_screen.heading.custom_minimum_size.y = 80.0
	act_screen.heading.add_theme_font_size_override("font_size", 48)
	act_screen.heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	BUTTON_TEXT_SHADOW.apply(act_screen.back_button)

func _on_back_requested() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu/menu.tscn")

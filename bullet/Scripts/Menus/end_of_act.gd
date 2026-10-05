extends Control

var completed_act: int = 1
var reputation: int = 0
var next_scene: PackedScene
var action_in_progress := false

@onready var title_label: Label = $CanvasLayer/Title
@onready var reputation_label: Label = $CanvasLayer/Reputation
@onready var continue_button: Button = $CanvasLayer/Buttons/Continue
@onready var main_menu_button: Button = $CanvasLayer/Buttons/MainMenu

func configure_act_result(act_number: int, score: int, target: PackedScene) -> void:
	completed_act = act_number
	reputation = score
	next_scene = target

func _ready() -> void:
	title_label.text = "End of Act %d" % completed_act
	reputation_label.text = "Reputation: %d" % reputation
	main_menu_button.visible = completed_act != 3
	continue_button.disabled = next_scene == null
	if not continue_button.disabled:
		continue_button.grab_focus()
	elif main_menu_button.visible:
		main_menu_button.grab_focus()

func _on_continue_pressed() -> void:
	if action_in_progress or next_scene == null:
		return
	action_in_progress = true
	$WoodenBlock.play()
	await $WoodenBlock.finished
	get_parent().transition_to_level(next_scene, 0.3)

func _on_main_menu_pressed() -> void:
	if action_in_progress or completed_act == 3:
		return
	action_in_progress = true
	$WoodenBlock.play()
	await $WoodenBlock.finished
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu/menu.tscn")

extends Label

const SCORE_SUMMARY = preload("res://Scripts/UI/Score/score_summary.gd")
const BUTTON_TEXT_SHADOW = preload("res://Scripts/UI/button_text_shadow.gd")

@export var reset_level: PackedScene
@export var tutorial_level: PackedScene
@export var sayin_label: Label
@export var stats_label: Label
@export var act_scores_container: HBoxContainer
@export var opened_from_menu := false

var menu_action_in_progress := false

@onready var score_tabs: TabBar = $"../ScoreTabs"

func _ready() -> void:
	_refresh_summary(score_tabs.current_tab == 0)
	BUTTON_TEXT_SHADOW.apply($"../Start")
	BUTTON_TEXT_SHADOW.apply($"../Quit")
	if opened_from_menu:
		score_tabs.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if opened_from_menu and SettingsManager.is_menu_back_event(event):
		get_viewport().set_input_as_handled()
		main_menu_button_pressed()

func _on_score_tab_changed(tab: int) -> void:
	_refresh_summary(tab == 0)

func _refresh_summary(use_recent: bool) -> void:
	var summary := ActManager.get_final_score_summary(use_recent)
	var view_name := "Recent" if use_recent else "Best"
	var score: int = summary["reputation"]
	self.text = str(score) + " Reputation"
	for index in range(3):
		var result: Dictionary = summary["acts"][index]
		var label := act_scores_container.get_child(index) as Label
		label.text = "Act %d %s\n%s" % [result["act"], view_name, "%d Reputation" % result["reputation"] if result["completed"] else "Unplayed"]
	stats_label.text = "Shots: %d | Resets: %d | Deaths: %d | Time: %s" % [
		summary["shots"],
		summary["resets"],
		summary["deaths"],
		SCORE_SUMMARY.format_time(summary["time_msec"])
	]
	
	sayin_label.text = SCORE_SUMMARY.saying_for_score(score)

func restart_button_pressed() -> void:
	if menu_action_in_progress:
		return
	menu_action_in_progress = true
	$"../../../../WoodenBlock".play()
	await $"../../../../WoodenBlock".finished
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("change_level"):
		ScoreBus.reset_run_stats()
		var next_level := reset_level if SettingsManager.skip_tutorial else tutorial_level
		if next_level == null:
			next_level = reset_level
		game_manager.change_level(next_level)

func main_menu_button_pressed() -> void:
	if menu_action_in_progress:
		return
	menu_action_in_progress = true
	$"../../../../WoodenBlock".play()
	await $"../../../../WoodenBlock".finished
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu/menu.tscn")
	

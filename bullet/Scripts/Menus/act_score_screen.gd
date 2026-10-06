extends Control

signal back_requested

const SCORE_SUMMARY = preload("res://Scripts/score_summary.gd")
const COLUMN_TITLES := ["Reputation", "Shots", "Resets", "Deaths", "Time"]
const COLUMN_KEYS := ["reputation", "shots", "resets", "deaths", "time_msec"]
const ACT_LEVEL_PATHS := [
	"res://Scenes/Levels/Act 1/act1_lvl1.tscn",
	"res://Scenes/Levels/Act 2/act2_lvl1.tscn",
	"res://Scenes/Levels/Act 3/act3_lvl1.tscn"
]

@export_range(1, 3) var selected_act: int = 1
var action_in_progress := false
var results: Array[Dictionary] = []
var sort_column := 0
var sort_ascending := false

@onready var leaderboard: Tree = $CanvasLayer/Panel/Container/Leaderboard
@onready var heading: Label = $CanvasLayer/Panel/Container/Congrats
@onready var context_label: Label = $CanvasLayer/Panel/Container/Label
@onready var records_label: Label = $CanvasLayer/Panel/Container/Records
@onready var replay_button: Button = $CanvasLayer/Panel/Container/Replay
@onready var back_button: Button = $CanvasLayer/Panel/Container/Back

func _ready() -> void:
	heading.text = "Act %d Local Leaderboard" % selected_act
	var stats := ActManager.get_act_stats(selected_act)
	replay_button.disabled = not ActManager.is_act_unlocked(selected_act)
	for column in range(5):
		leaderboard.set_column_title(column, COLUMN_TITLES[column])
		leaderboard.set_column_title_alignment(column, HORIZONTAL_ALIGNMENT_CENTER)
		leaderboard.set_column_expand(column, true)
		leaderboard.set_column_custom_minimum_width(column, 150)
	leaderboard.column_titles_visible = true
	results = ActManager.get_act_leaderboard(selected_act)
	_refresh_leaderboard()
	if results.is_empty():
		context_label.text = "No completed runs recorded for this act yet."
		if not stats.is_empty():
			context_label.text = "Replay this act to add a leaderboard entry."
	if stats.is_empty():
		records_label.text = "High Score: Unplayed | Best Time: -- | Completions: 0"
	else:
		records_label.text = "High Score: %d | Best Time: %s | Completions: %d" % [
			stats.get("high_score", 0), SCORE_SUMMARY.format_time(stats.get("best_time_msec", 0)), stats.get("completions", 0)
		]
	back_button.grab_focus()

func _on_column_title_clicked(column: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT or column < 0 or column >= COLUMN_KEYS.size():
		return
	if column == sort_column:
		sort_ascending = not sort_ascending
	else:
		sort_column = column
		sort_ascending = column != 0
	_refresh_leaderboard()

func _refresh_leaderboard() -> void:
	var selected_result: Variant = null
	if leaderboard.get_selected() != null:
		selected_result = leaderboard.get_selected().get_metadata(0)
	var key: String = COLUMN_KEYS[sort_column]
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a[key] != b[key]:
			return a[key] < b[key] if sort_ascending else a[key] > b[key]
		if a["reputation"] != b["reputation"]:
			return a["reputation"] > b["reputation"]
		return a["time_msec"] < b["time_msec"]
	)
	leaderboard.clear()
	for column in range(COLUMN_TITLES.size()):
		var title: String = COLUMN_TITLES[column]
		if column == sort_column:
			title += " \u2191" if sort_ascending else " \u2193"
		leaderboard.set_column_title(column, title)
	var tree_root := leaderboard.create_item()
	var selected_row: TreeItem
	for result: Dictionary in results:
		var row := leaderboard.create_item(tree_root)
		var values := [str(result["reputation"]), str(result["shots"]), str(result["resets"]), str(result["deaths"]), SCORE_SUMMARY.format_time(result["time_msec"])]
		for column in range(COLUMN_TITLES.size()):
			row.set_text(column, values[column])
			row.set_text_alignment(column, HORIZONTAL_ALIGNMENT_CENTER)
		row.set_metadata(0, result)
		if selected_row == null and result == selected_result:
			selected_row = row
	if not results.is_empty():
		if selected_row == null:
			selected_row = tree_root.get_first_child()
		selected_row.select(0)
		context_label.text = "Sorted by %s (%s). Click a heading to change the order." % [COLUMN_TITLES[sort_column], "ascending" if sort_ascending else "descending"]

func _unhandled_input(event: InputEvent) -> void:
	if SettingsManager.is_menu_back_event(event):
		get_viewport().set_input_as_handled()
		_on_back_pressed()

func _on_back_pressed() -> void:
	if action_in_progress:
		return
	action_in_progress = true
	$WoodenBlock.play()
	await $WoodenBlock.finished
	back_requested.emit()

func _on_replay_pressed() -> void:
	if action_in_progress or not ActManager.is_act_unlocked(selected_act):
		return
	action_in_progress = true
	$WoodenBlock.play()
	await $WoodenBlock.finished
	ActManager.ActSelected = true
	ActManager.SelectedAct = load(ACT_LEVEL_PATHS[selected_act - 1])
	ScoreBus.reset_run_stats()
	MusicManager.stop_music()
	get_tree().change_scene_to_file("res://Scenes/Levels/main_game.tscn")

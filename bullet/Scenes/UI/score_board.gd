extends Label

@export var reset_level: PackedScene
@export var tutorial_level: PackedScene
@export var sayin_label: Label
@export var stats_label: Label

var score_label: Node

func _ready() -> void:
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	var Canvas := game_manager.find_child("CanvasLayer", true, false)
	score_label = Canvas.find_child("ScoreLabel",true, false)
	var score = score_label.score
	self.text = str(score) + " Reputation"
	stats_label.text = "Shots: %d | Resets: %d | Deaths: %d | Time: %s" % [
		ScoreBus.shots_taken,
		ScoreBus.reset_count,
		ScoreBus.death_count,
		ScoreBus.get_elapsed_run_time_text()
	]
	
	if score >= 70000:
		sayin_label.text = "I tip my hat to you"
	elif score >= 60000:
		sayin_label.text ="Well you surely ain't lackin'"
	elif score >= 40000:
		sayin_label.text ="Missed it by a hair"
	elif score >= 20000:
		sayin_label.text ="Well bless your heart"
	elif score >= 0:
		sayin_label.text ="If you find yourself in a hole, first to do is stop diggin'"

func restart_button_pressed() -> void:
	$"../../../../WoodenBlock".play()
	await $"../../../../WoodenBlock".finished
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("change_level"):
		ScoreBus.reset_run_stats()
		var next_level := reset_level if SettingsManager.skip_tutorial else tutorial_level
		if next_level == null:
			next_level = reset_level
		game_manager.change_level(next_level)

func exit_button_pressed() -> void:
	$"../../../../WoodenBlock".play()
	await $"../../../../WoodenBlock".finished
	JavaScriptBridge.eval("window.close()")
	get_tree().quit()
	

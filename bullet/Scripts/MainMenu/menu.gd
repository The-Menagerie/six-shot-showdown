extends Control

const MENU_MUSIC = preload("res://Assets/Music/CowboyMenuSong.mp3")

func _ready() -> void:
	MusicManager.play_music(MENU_MUSIC, -10.0)

func start_button_pressed() -> void:
	$WoodenBlock.play()
	await $WoodenBlock.finished
	ScoreBus.reset_run_stats()
	get_tree().change_scene_to_file("res://Scenes/Cutscene.tscn")

func options_button_pressed() -> void:
	$WoodenBlock.play()
	await $WoodenBlock.finished
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu/options.tscn")

func exit_button_pressed() -> void:
	$WoodenBlock.play()
	await $WoodenBlock.finished
	JavaScriptBridge.eval("window.close()")
	get_tree().quit()
	

func back_button_pressed() -> void:
	$WoodenBlock.play()
	await $WoodenBlock.finished
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu/menu.tscn")

extends Control

const MENU_MUSIC = preload("res://Assets/Music/CowboyMenuSong.mp3")
const OPTIONS_SCENE_PATH := "res://Scenes/UI/MainMenu/options.tscn"
const PLAYGROUND_SCENE_PATH := "res://Scenes/playground.tscn"
const PLAYGROUND_EASTER_EGG := "play"

var easter_egg_buffer := ""

func _ready() -> void:
	MusicManager.play_music(MENU_MUSIC, -10.0)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_options_menu():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var typed_character := char(event.unicode).to_lower()
		if typed_character.is_empty() or not typed_character.is_valid_identifier():
			easter_egg_buffer = ""
			return

		easter_egg_buffer += typed_character
		if easter_egg_buffer.length() > PLAYGROUND_EASTER_EGG.length():
			easter_egg_buffer = easter_egg_buffer.right(PLAYGROUND_EASTER_EGG.length())

		if easter_egg_buffer == PLAYGROUND_EASTER_EGG:
			easter_egg_buffer = ""
			get_viewport().set_input_as_handled()
			get_tree().change_scene_to_file(PLAYGROUND_SCENE_PATH)

func start_button_pressed() -> void:
	$WoodenBlock.play()
	await $WoodenBlock.finished
	ScoreBus.reset_run_stats()
	if SettingsManager.skip_cutscenes:
		MusicManager.stop_music()
		get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
	else:
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


func _is_options_menu() -> bool:
	var current_scene := get_tree().current_scene
	return current_scene != null and current_scene.scene_file_path == OPTIONS_SCENE_PATH

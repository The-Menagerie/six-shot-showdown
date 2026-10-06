extends Control

const MENU_MUSIC = preload("res://Assets/Music/CowboyMenuSong.mp3")
const OPTIONS_SCENE_PATH := "res://Scenes/UI/MainMenu/options.tscn"
const PLAYGROUND_SCENE_PATH := "res://Scenes/Levels/playground.tscn"
const PLAYGROUND_EASTER_EGG := "play"

var easter_egg_buffer := ""
var menu_action_in_progress := false

var ActSlider
var ActSelect

func _ready() -> void:
	MusicManager.play_music(MENU_MUSIC, -10.0)
	_update_continue_visibility()
	SettingsManager.focus_first_menu_control(self)
	if get_node_or_null("ActSelect") != null:
		ActSlider = $ActSelectSlider
		ActSelect = $ActSelect
		var back_button = $ActSelect/BackButtonContainer/BackButton
		back_button.pressed.connect(on_back_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_options_menu():
		return
	if SettingsManager.is_menu_back_event(event):
		get_viewport().set_input_as_handled()
		back_button_pressed()
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
			_change_menu_scene(PLAYGROUND_SCENE_PATH)

func new_game_button_pressed() -> void:
	if menu_action_in_progress:
		return
	menu_action_in_progress = true
	$WoodenBlock.play()
	await $WoodenBlock.finished
	ActManager.ActSelected = false
	ActManager.SelectedAct = null
	ScoreBus.reset_run_stats()
	if SettingsManager.skip_cutscenes:
		MusicManager.stop_music()
		_change_menu_scene("res://Scenes/Levels/main_game.tscn")
	else:
		_change_menu_scene("res://Scenes/Levels/Cutscene.tscn")

func options_button_pressed() -> void:
	if menu_action_in_progress:
		return
	menu_action_in_progress = true
	$WoodenBlock.play()
	await $WoodenBlock.finished
	_change_menu_scene("res://Scenes/UI/MainMenu/options.tscn")

func credits_button_pressed() -> void:
	if menu_action_in_progress:
		return
	menu_action_in_progress = true
	$WoodenBlock.play()
	await $WoodenBlock.finished
	_change_menu_scene("res://Scenes/UI/MainMenu/credits.tscn")

func statistics_button_pressed() -> void:
	if menu_action_in_progress or not ActManager.has_completed_game():
		return
	menu_action_in_progress = true
	$WoodenBlock.play()
	await $WoodenBlock.finished
	_change_menu_scene("res://Scenes/UI/MainMenu/statistics.tscn")

func exit_button_pressed() -> void:
	if menu_action_in_progress:
		return
	menu_action_in_progress = true
	$WoodenBlock.play()
	await $WoodenBlock.finished
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.close()")
	get_tree().quit()
	

func back_button_pressed() -> void:
	if menu_action_in_progress:
		return
	menu_action_in_progress = true
	$WoodenBlock.play()
	await $WoodenBlock.finished
	_change_menu_scene("res://Scenes/UI/MainMenu/menu.tscn")

func key_bindings_pressed() -> void:
	$WoodenBlock.play()
	$OptionsContainer.hide()
	$KeyBindings.open_page()

func key_bindings_closed() -> void:
	$OptionsContainer.show()
	SettingsManager.focus_first_menu_control($OptionsContainer)


func _is_options_menu() -> bool:
	var current_scene := get_tree().current_scene
	return current_scene != null and current_scene.scene_file_path == OPTIONS_SCENE_PATH


func continue_button_pressed() -> void:
	if not ActManager.is_act_unlocked(2):
		return
	$WoodenBlock.play()
	await $WoodenBlock.finished
	ActSlider.play("act_select_slide")
	pass # Replace with function body.

func on_back_pressed() -> void:
	$WoodenBlock.play()
	ActSlider.play_backwards("act_select_slide")
	pass # Replace with function body.

func _on_profiles_opened() -> void:
	ActSelect.set_process(false)

func _on_profiles_closed() -> void:
	ActSelect.set_process(true)

func _on_profile_changed() -> void:
	_update_continue_visibility()
	ActSelect.anim_player.stop()
	ActSelect.anim_player.speed_scale = 1.0
	ActSelect.chamber_sprite.texture.region = Rect2(0, 0, 128, 128)
	ActSelect.cylinder_rotator.rotation_degrees = 0.0
	ActSelect.selected_act = 1
	ActSelect.change_act_data(1)

func _update_continue_visibility() -> void:
	var continue_button := get_node_or_null("ButtonContainer/Continue") as Button
	if continue_button != null:
		continue_button.visible = ActManager.is_act_unlocked(2)
	var statistics_button := get_node_or_null("ButtonContainer/Statistics") as Button
	if statistics_button != null:
		statistics_button.visible = ActManager.has_completed_game()


func _change_menu_scene(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		menu_action_in_progress = false
		push_error("Could not open menu scene %s: %s" % [scene_path, error_string(error)])

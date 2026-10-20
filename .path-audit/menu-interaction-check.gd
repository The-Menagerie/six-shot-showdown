extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("MENU_CHECK ", "PASS " if ok else "FAIL ", label)
	if not ok:
		failures += 1
func open_menu() -> void:
	change_scene_to_file("res://Scenes/UI/MainMenu/menu.tscn")
	await process_frame
	await process_frame
func click(button: Button) -> void:
	var point = button.get_global_rect().get_center()
	var motion = InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var event = InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await create_timer(0.5).timeout
func run() -> void:
	await open_menu()
	await click(current_scene.get_node("ProfileButton"))
	check(current_scene.get_node("ProfileButton/Profiles").visible, "profile button opens dialog")
	current_scene.get_node("ProfileButton/Profiles").hide()
	current_scene.get_node("ProfileButton")._on_closed()
	await click(current_scene.get_node("ButtonContainer/Options"))
	check(current_scene.scene_file_path.ends_with("options.tscn"), "Options mouse click changes scene")
	check(current_scene.get_node("KeyBindings").has_method("open_page"), "key bindings script loads")
	current_scene.back_button_pressed()
	await create_timer(0.5).timeout
	check(current_scene.scene_file_path.ends_with("menu.tscn"), "Options back returns to menu")
	await click(current_scene.get_node("CreditsButton"))
	check(current_scene.scene_file_path.ends_with("credits.tscn"), "Credits mouse click changes scene")
	await open_menu()
	current_scene.menu_action_in_progress = true
	current_scene._change_menu_scene("res://Scenes/__missing_menu_check__.tscn")
	check(not current_scene.menu_action_in_progress, "failed transition releases button lock")
	root.get_node("SettingsManager").skip_cutscenes = false
	await click(current_scene.get_node("ButtonContainer/NewGame"))
	check(current_scene.scene_file_path == "res://Scenes/Levels/Cutscene.tscn", "New Game mouse click opens moved cutscene")
	print("MENU_CHECK_DONE failures=", failures)
	quit(failures)

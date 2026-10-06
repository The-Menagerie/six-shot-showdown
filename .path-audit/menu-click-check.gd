extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	change_scene_to_file("res://Scenes/UI/MainMenu/menu.tscn")
	await process_frame
	await process_frame
	var menu = current_scene
	for path in ["ProfileButton", "ButtonContainer/NewGame", "ButtonContainer/Options", "ActSelect"]:
		var node = menu.get_node(path)
		print("CONTROL ", path, " rect=", node.get_global_rect(), " visible=", node.is_visible_in_tree())
	print("DIALOGS ", menu.get_node("ProfileButton/Profiles").visible, " ", menu.get_node("ProfileButton/Profiles/Confirmation").visible)
	var button = menu.get_node("ButtonContainer/Options")
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
	await create_timer(1.5).timeout
	print("AFTER_CLICK ", current_scene.scene_file_path, " busy=", current_scene.get("menu_action_in_progress"))
	quit()


extends SceneTree
func _initialize() -> void:
	var scene = load("res://Scenes/UI/MainMenu/menu.tscn")
	if scene == null:
		quit(1)
		return
	var menu = scene.instantiate()
	var button = menu.get_node_or_null("ProfileButton")
	if button is Button and button.visible and button.get_node_or_null("Profiles") != null:
		print("PROFILE_CHECK_PASS: main menu contains visible ProfileButton and Profiles dialog; position=", button.position)
		menu.free()
		quit(0)
	else:
		print("PROFILE_CHECK_FAIL")
		menu.free()
		quit(1)

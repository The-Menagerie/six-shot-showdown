extends Control

signal show_options()
signal hide_options()

func _ready() -> void:
	hide()

func close_menu() -> void:
	$AnimationPlayer.play_backwards("p_blur")
	await $AnimationPlayer.animation_finished
	visible = false
	get_tree().paused = false
	hide()

func open_menu() -> void:
	visible = true
	get_tree().paused = true
	show()
	$AnimationPlayer.play("p_blur")
	await $AnimationPlayer.animation_finished

func _input(event) -> void:
	if event.is_action_pressed("menu"):
		if visible:
			close_menu()
		else:
			open_menu()
			hide_options.emit()

func resume() -> void:
	$WoodenBlock.play()
	await $WoodenBlock.finished
	close_menu()

func restart() -> void:
	$WoodenBlock.play()
	await $WoodenBlock.finished
	visible = false
	get_tree().paused = false
	hide()
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("reset_current_level"):
		game_manager.reset_current_level()

func option() -> void:
	$WoodenBlock.play()
	await $WoodenBlock.finished
	$AnimationPlayer.play_backwards("p_blur")
	await $AnimationPlayer.animation_finished
	visible = false
	hide()
	show_options.emit()

func quit() -> void:
	$WoodenBlock.play()
	await $WoodenBlock.finished
	visible = false
	get_tree().paused = false
	hide()
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu/menu.tscn")

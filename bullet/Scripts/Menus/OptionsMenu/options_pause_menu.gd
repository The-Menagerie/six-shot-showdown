extends Control

signal show_pause()

func _ready() -> void:
	hide()

func show_options() -> void:
	visible = true
	show()
	SettingsManager.focus_first_menu_control($OptionsContainer)
	$AnimationPlayer.play("blur")
	await $AnimationPlayer.animation_finished

func hide_options() -> void:
	if $KeyBindings.visible:
		$KeyBindings.close_page()
	visible = false
	$AnimationPlayer.play_backwards("blur")
	await $AnimationPlayer.animation_finished
	hide()

func _input(event: InputEvent) -> void:
	if not visible or $KeyBindings.visible or SettingsManager.is_capturing_binding:
		return
	if SettingsManager.is_menu_back_event(event):
		get_viewport().set_input_as_handled()
		back_presed()

func back_presed() -> void:
	$WoodenBlock.play()
	await $WoodenBlock.finished
	hide_options()
	show_pause.emit()

func key_bindings_pressed() -> void:
	$WoodenBlock.play()
	$OptionsContainer.hide()
	$KeyBindings.open_page()

func key_bindings_closed() -> void:
	$OptionsContainer.show()
	SettingsManager.focus_first_menu_control($OptionsContainer)

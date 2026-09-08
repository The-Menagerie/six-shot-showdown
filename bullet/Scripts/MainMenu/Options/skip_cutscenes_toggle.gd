extends CheckButton

func _ready() -> void:
	button_pressed = SettingsManager.skip_cutscenes
	toggled.connect(_on_toggled)

func _on_toggled(toggled_on: bool) -> void:
	SettingsManager.set_skip_cutscenes(toggled_on)

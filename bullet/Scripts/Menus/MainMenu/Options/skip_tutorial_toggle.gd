extends CheckButton

func _ready() -> void:
	button_pressed = SettingsManager.skip_tutorial
	toggled.connect(_on_toggled)

func _on_toggled(toggled_on: bool) -> void:
	SettingsManager.set_skip_tutorial(toggled_on)

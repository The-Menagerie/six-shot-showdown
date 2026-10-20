extends Node2D

func _ready():
	if SettingsManager != null and SettingsManager.has_method("apply_custom_cursor"):
		SettingsManager.apply_custom_cursor()

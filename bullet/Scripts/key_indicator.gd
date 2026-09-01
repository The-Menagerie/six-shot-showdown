extends Control

@export var regular_key_texture: Texture2D
@export var single_use_key_texture: Texture2D

var game_manager: Node
@onready var icon: Sprite2D = $Icon

func _ready() -> void:
	hide()
	BulletBus.player_key_changed.connect(_on_player_key_changed)

	game_manager = get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_signal("level_changed"):
		game_manager.level_changed.connect(_on_level_changed)

func _on_player_key_changed(has_key: bool, is_single_use: bool) -> void:
	if is_instance_valid(icon):
		icon.texture = single_use_key_texture if is_single_use else regular_key_texture
	visible = has_key

func _on_level_changed(_level_path: String) -> void:
	hide()

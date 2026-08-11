extends Area2D

var scene_reset_queued := false

func _ready() -> void:
	add_to_group("enemy_hazard")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not scene_reset_queued:
			scene_reset_queued = true
			ScoreBus.register_player_death()
			var game_manager := get_tree().root.find_child("MainGame", true, false)
			if game_manager != null and game_manager.has_method("reset_current_level"):
				game_manager.reset_current_level()
		return

	if body.is_in_group("enemy") and body.has_method("handle_death"):
		body.handle_death()

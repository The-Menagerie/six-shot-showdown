extends Area2D

@export var current_level: Node


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Attempted to move to next level")
		current_level.send_to_next_level()

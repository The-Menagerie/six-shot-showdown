extends Node2D

@onready var hazard_area: Area2D = $Area2D
@export var anim_player:Node

var scene_reset_queued := false

func _ready() -> void:
	add_to_group("enemy_hazard")
	anim_player.play_section("idle")
	if is_instance_valid(hazard_area):
		hazard_area.add_to_group("enemy_hazard")
		hazard_area.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var bodies = hazard_area.get_overlapping_bodies()
	if bodies:
		for body in bodies:
			if body.is_in_group("player"):
				ScoreBus.player_burning()


func _on_body_entered(body: Node2D) -> void:
	#if body.is_in_group("player"):
		#if not scene_reset_queued:
			#scene_reset_queued = true
			#ScoreBus.player_died_to_spikes()
			#var game_manager := get_tree().root.find_child("MainGame", true, false)
			#if game_manager != null and game_manager.has_method("reset_current_level"):
				#game_manager.reset_current_level()
		#return

	if body.is_in_group("enemy") and body.has_method("handle_death"):
		body.handle_death()

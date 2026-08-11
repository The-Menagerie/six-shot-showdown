extends Node2D

@export var pickup_group: StringName = &"player"
@export var fade_duration := 0.2

@onready var unlock_area: Area2D = $UnlockArea
@onready var unlock_collision: CollisionShape2D = $UnlockArea/CollisionShape2D
@onready var wall_collision: CollisionShape2D = $WallBody/CollisionShape2D
@onready var unlock_audio: AudioStreamPlayer = get_node_or_null("Unlock")

var is_unlocked := false

func _ready() -> void:
	unlock_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_unlocked:
		return
	if not body.is_in_group(pickup_group):
		return
	if body.get("has_key") != true:
		return

	is_unlocked = true
	_disable_collisions()
	_play_unlock_sound()
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await fade_tween.finished
	queue_free()

func _disable_collisions() -> void:
	if is_instance_valid(wall_collision):
		wall_collision.set_deferred("disabled", true)

	if is_instance_valid(unlock_collision):
		unlock_collision.set_deferred("disabled", true)

	if is_instance_valid(unlock_area):
		unlock_area.set_deferred("monitoring", false)
		unlock_area.set_deferred("monitorable", false)

func _play_unlock_sound() -> void:
	if not is_instance_valid(unlock_audio) or unlock_audio.stream == null:
		return

	var parent_node := get_parent()
	if parent_node == null:
		return

	var detached_audio := AudioStreamPlayer.new()
	detached_audio.stream = unlock_audio.stream
	detached_audio.bus = unlock_audio.bus
	parent_node.add_child(detached_audio)
	_configure_audio_for_bullet_time(detached_audio)
	detached_audio.finished.connect(detached_audio.queue_free)
	detached_audio.play()

func _configure_audio_for_bullet_time(audio_player: AudioStreamPlayer) -> void:
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("configure_audio_player_for_bullet_time"):
		game_manager.configure_audio_player_for_bullet_time(audio_player)

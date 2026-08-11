extends Node2D

signal picked_up(by: Node2D)

@export var pickup_group: StringName = &"player"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_audio: AudioStreamPlayer = get_node_or_null("PickUp")

var is_collected := false
var is_carried := false

func _ready() -> void:
	animation_player.play(&"Key")
	pickup_area.body_entered.connect(_on_body_entered)
	_update_pickup_state()

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if is_carried:
		return
	if not body.is_in_group(pickup_group):
		return

	is_collected = true
	if body.has_method("collect_key"):
		body.collect_key()
	picked_up.emit(body)
	_play_pickup_sound()
	queue_free()

func set_carried_state(carried: bool) -> void:
	is_carried = carried
	visible = not carried
	_update_pickup_state()

func drop_from_carrier() -> void:
	is_carried = false
	visible = true
	_update_pickup_state()

func _update_pickup_state() -> void:
	if is_instance_valid(pickup_area):
		pickup_area.set_deferred("monitoring", not is_carried)
		pickup_area.set_deferred("monitorable", not is_carried)

func _play_pickup_sound() -> void:
	if not is_instance_valid(pickup_audio) or pickup_audio.stream == null:
		return

	var parent_node := get_parent()
	if parent_node == null:
		return

	var detached_audio := AudioStreamPlayer.new()
	detached_audio.stream = pickup_audio.stream
	detached_audio.bus = pickup_audio.bus
	parent_node.add_child(detached_audio)
	_configure_audio_for_bullet_time(detached_audio)
	detached_audio.finished.connect(detached_audio.queue_free)
	detached_audio.play()

func _configure_audio_for_bullet_time(audio_player: AudioStreamPlayer) -> void:
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("configure_audio_player_for_bullet_time"):
		game_manager.configure_audio_player_for_bullet_time(audio_player)

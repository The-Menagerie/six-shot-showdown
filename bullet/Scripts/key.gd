extends Node2D

signal picked_up(by: Node2D)

@export var pickup_group: StringName = &"player"
@export var single_use := false
## Seconds the player must remain in pickup range before collecting this key.
@export_range(0.0, 10.0, 0.05, "or_greater", "suffix:s") var pickup_delay := 0.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_audio: AudioStreamPlayer = get_node_or_null("PickUp")

var is_collected := false
var is_carried := false
var pickup_delay_timer: Timer
var pending_collector: Node2D

func _ready() -> void:
	pickup_delay_timer = Timer.new()
	pickup_delay_timer.one_shot = true
	pickup_delay_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(pickup_delay_timer)
	pickup_delay_timer.timeout.connect(_on_pickup_delay_timeout)
	animation_player.play(&"Key")
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.body_exited.connect(_on_body_exited)
	_update_pickup_state()

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if is_carried:
		return
	if not body.is_in_group(pickup_group):
		return
	if pickup_delay > 0.0:
		if not is_instance_valid(pending_collector):
			pending_collector = body
			pickup_delay_timer.start(pickup_delay)
		return
	_collect(body)

func _collect(body: Node2D) -> void:
	if is_collected or is_carried:
		return

	is_collected = true
	if body.has_method("collect_key"):
		body.collect_key(single_use)
	picked_up.emit(body)
	_play_pickup_sound()
	queue_free()

func set_carried_state(carried: bool) -> void:
	is_carried = carried
	visible = not carried
	_cancel_pickup_delay()
	_update_pickup_state()

func drop_from_carrier() -> void:
	is_carried = false
	visible = true
	_cancel_pickup_delay()
	_update_pickup_state()

func _on_body_exited(body: Node2D) -> void:
	if body == pending_collector:
		_cancel_pickup_delay()

func _cancel_pickup_delay() -> void:
	pending_collector = null
	if not is_instance_valid(pickup_delay_timer):
		return
	pickup_delay_timer.stop()

func _on_pickup_delay_timeout() -> void:
	var body := pending_collector
	pending_collector = null
	if is_instance_valid(body) and pickup_area.overlaps_body(body) and body.is_in_group(pickup_group):
		_collect(body)

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

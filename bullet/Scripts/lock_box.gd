extends Node2D

@export var pickup_group: StringName = &"player"
@export var second_pickup_group: StringName = &"key_bullet"
@export var fade_duration := 0.2

@onready var unlock_area: Area2D = $UnlockArea
@onready var bullet_unlock: Area2D = $BulletUnlockArea
@onready var unlock_collision: CollisionShape2D = $UnlockArea/CollisionShape2D
@onready var wall_collision: CollisionShape2D = $WallBody/CollisionShape2D
@onready var unlock_audio: AudioStreamPlayer = get_node_or_null("Unlock")

var is_unlocked := false

func _ready() -> void:
	add_to_group("lock")
	unlock_area.body_entered.connect(_on_body_entered)
	bullet_unlock.body_entered.connect(_bullet_entered_check)

func _on_body_entered(body: Node2D) -> void:
	# Wait until all door overlaps for this physics frame are available.
	call_deferred("_try_unlock_for_body", body)

func _try_unlock_for_body(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if is_unlocked:
		return
	if not unlock_area.overlaps_body(body):
		return
	if not body.is_in_group(pickup_group):
		return
	if body.get("has_key") != true:
		return
	var consumes_key: bool = body.get("has_single_use_key") == true
	var selected_door = self
	if consumes_key and body.get("has_permanent_key") != true:
		selected_door = _preferred_door_for(body)
		if selected_door == null:
			return
	selected_door.unlock()
	if consumes_key and body.has_method("consume_key"):
		body.consume_key()

func _preferred_door_for(body: Node2D) -> Node2D:
	var best_door: Node2D = null
	var best_priority := -1
	var best_distance := INF
	for door in get_tree().get_nodes_in_group("lock"):
		if door.is_unlocked or not body.is_in_group(door.pickup_group):
			continue
		if not door.unlock_area.overlaps_body(body):
			continue
		var priority: int = door._standing_priority(body)
		var distance: float = body.global_position.distance_squared_to(door.global_position)
		if priority > best_priority or (priority == best_priority and distance < best_distance):
			best_door = door
			best_priority = priority
			best_distance = distance
	return best_door

func _standing_priority(body: Node2D) -> int:
	if body is CharacterBody2D:
		for index in range(body.get_slide_collision_count()):
			var collision: KinematicCollision2D = body.get_slide_collision(index)
			if collision.get_collider() == wall_collision.get_parent() and collision.get_normal().y < -0.7:
				return 2
	# Also prefer the door directly below when approaching or landing on it.
	var local_position := wall_collision.to_local(body.global_position)
	var wall_bounds := wall_collision.shape.get_rect()
	if local_position.y < wall_bounds.position.y and local_position.x >= wall_bounds.position.x and local_position.x <= wall_bounds.end.x:
		return 1
	return 0

func _bullet_entered_check(body:Node2D) ->void:
	if is_unlocked or body.is_queued_for_deletion():
		return
	if not body.is_in_group(second_pickup_group):
		return
	if body.get("has_key") != true:
		return
	if body.get("single_use") == true:
		body.queue_free()
	unlock()
	
func unlock()->void:
	is_unlocked = true
	_disable_collisions()
	_play_unlock_sound()
	_on_unlocked()
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await fade_tween.finished
	queue_free()

func _on_unlocked() -> void:
	pass

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

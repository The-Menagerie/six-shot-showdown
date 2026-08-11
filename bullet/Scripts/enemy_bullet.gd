extends CharacterBody2D

@export var speed : float = 320.0
@export var lifetime : float = 2.5
@export var rope_pass_through_distance : float = 6.0

const RICOCHET_SOUND = preload("res://Assets/SoundEffects/ricochet.wav")

var direction : Vector2 = Vector2.RIGHT
var time_alive : float = 0.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	add_to_group("enemy_projectile")
	if is_instance_valid(animation_player) and animation_player.has_animation("Spin"):
		animation_player.play("Spin")

func _physics_process(delta):
	velocity = direction * speed
	var next_position: Vector2 = global_position + velocity * delta
	if _try_cut_rope_between(global_position, next_position):
		global_position = next_position
		rotation = direction.angle()
		return

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)

	if collision:
		_handle_hit(collision.get_collider())
		queue_free()
		return

	rotation = direction.angle()
	time_alive += delta

	if time_alive >= lifetime:
		queue_free()

func set_direction(new_direction: Vector2):
	if new_direction == Vector2.ZERO:
		return

	direction = new_direction.normalized()
	rotation = direction.angle()

func _handle_hit(collider: Object):
	if collider == null:
		_play_ricochet()
		return

	var hit_node: Node = collider as Node
	if hit_node == null:
		_play_ricochet()
		return

	if hit_node.is_in_group("player"):
		_apply_score_damage()
		return

	var parent: Node = hit_node.get_parent()
	if parent != null and parent.is_in_group("player"):
		_apply_score_damage()
		return

	_play_ricochet()

func _apply_score_damage():
	ScoreBus.player_hit_by_enemy_bullet()
	#var game_manager = get_tree().root.find_child("MainGame", true, false)
	#if game_manager != null and game_manager.has_method("change_score"):
		#game_manager.change_score(-ScoreBus.score_on_enemy_bullet_hit)

func _play_ricochet():
	var parent: Node = get_parent()
	if parent == null:
		return

	var ricochet_audio: AudioStreamPlayer = AudioStreamPlayer.new()
	ricochet_audio.stream = RICOCHET_SOUND
	ricochet_audio.bus = "sfx"
	parent.add_child(ricochet_audio)
	_configure_audio_for_bullet_time(ricochet_audio)
	ricochet_audio.finished.connect(ricochet_audio.queue_free)
	ricochet_audio.play()

func _try_cut_rope(collision: KinematicCollision2D) -> bool:
	var collider: Object = collision.get_collider()
	if collider == null:
		return false
	if not collider.has_method("cut_by_bullet"):
		return false

	return collider.cut_by_bullet(collision.get_position())

func _try_cut_rope_between(segment_start: Vector2, segment_end: Vector2) -> bool:
	var ropes: Array[Node] = get_tree().get_nodes_in_group("rope")
	for rope: Node in ropes:
		if rope.has_method("cut_along_segment") and rope.cut_along_segment(segment_start, segment_end, rope_pass_through_distance):
			return true

	return false

func _configure_audio_for_bullet_time(audio_player: AudioStreamPlayer) -> void:
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("configure_audio_player_for_bullet_time"):
		game_manager.configure_audio_player_for_bullet_time(audio_player)

extends Node2D

@export var drop_gravity : float = 900.0
@export var floor_snap_distance : float = 6.0
@export var muzzle_distance : float = 12.0
@export var dropped_lifetime : float = 6.0
@export var fade_duration : float = 1.25

var drop_velocity : Vector2 = Vector2.ZERO
var is_dropping := false
var despawn_timer := 0.0
var is_despawning := false

const ENEMY_BULLET_SCENE = preload("res://Scenes/Objects/Enemies/EnemyBullet.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var gunshot_audio: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	modulate.a = 1.0
	if is_instance_valid(animation_player):
		animation_player.play("Idle")

func _physics_process(delta):
	if is_despawning:
		_update_despawn(delta)
		if not is_inside_tree():
			return

	if not is_dropping:
		return

	drop_velocity.y += drop_gravity * delta
	var next_position = global_position + drop_velocity * delta
	var space_state = get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		next_position + Vector2(0.0, floor_snap_distance)
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	if not result.is_empty():
		global_position = result.position
		drop_velocity = Vector2.ZERO
		is_dropping = false
		return

	global_position = next_position

func drop(initial_velocity: Vector2 = Vector2.ZERO):
	drop_velocity = initial_velocity
	is_dropping = true
	is_despawning = true
	despawn_timer = dropped_lifetime
	modulate.a = 1.0

func fire(direction: Vector2, parent: Node):
	if is_dropping or parent == null or direction == Vector2.ZERO:
		return

	if is_instance_valid(animation_player) and animation_player.has_animation("Attack"):
		animation_player.play("Attack")

	if is_instance_valid(gunshot_audio):
		gunshot_audio.play()

	var bullet = ENEMY_BULLET_SCENE.instantiate()
	parent.add_child(bullet)
	bullet.global_position = global_position + direction.normalized() * muzzle_distance
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction)

func _update_despawn(delta: float) -> void:
	despawn_timer = max(despawn_timer - delta, 0.0)

	if fade_duration > 0.0 and despawn_timer <= fade_duration:
		modulate.a = clamp(despawn_timer / fade_duration, 0.0, 1.0)

	if despawn_timer <= 0.0:
		queue_free()

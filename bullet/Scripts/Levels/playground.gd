extends LevelRoot

const RESPAWN_KEY := KEY_T
const REFILL_KEY := KEY_B
const RESPAWN_POWERUPS_KEY := KEY_P
const DUPLICATE_FLAGS := Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS | Node.DUPLICATE_USE_INSTANTIATION
const PLAYGROUND_POWERUP_GROUP := &"playground_powerup"
const PLAYGROUND_SPAWNED_OBJECT_GROUP := &"playground_spawned_object"
const TARGET_SCENE := preload("res://Scenes/Objects/Breakables/target.tscn")
const ENEMY_SCENE := preload("res://Scenes/Objects/Enemies/outlaw.tscn")
const CRATE_SCENE := preload("res://Scenes/Objects/Breakables/crate.tscn")
const BOULDER_SCENE := preload("res://Scenes/Objects/Boulder.tscn")
const KEY_SCENE := preload("res://Scenes/Objects/PowerUps/Key.tscn")
const LOCK_BOX_SCENE := preload("res://Scenes/Objects/LockBox.tscn")
const SPIKES_SCENE := preload("res://Scenes/Objects/Spikes.tscn")
const PLATFORM_SCENE := preload("res://Scenes/Objects/Platform.tscn")
const DYNAMITE_SCENE := preload("res://Scenes/Objects/Dynamite.tscn")

@export var powerups: Array[Node] = []

var spawn_records: Array[Dictionary] = []
var powerup_spawn_records: Array[Dictionary] = []
var is_respawning := false
var is_respawning_powerups := false

@onready var player: Node2D = $Player
@onready var player_camera: Camera2D = $Camera2D


func _ready() -> void:
	super._ready()
	_capture_spawn_records()
	_capture_powerup_spawn_records()
	player_camera.global_position = player.global_position


func _process(_delta: float) -> void:
	player_camera.global_position = player.global_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == RESPAWN_KEY:
			respawn_destroyables_and_enemies()
			get_viewport().set_input_as_handled()
		elif event.keycode == REFILL_KEY:
			refill_bullets()
			get_viewport().set_input_as_handled()
		elif event.keycode == RESPAWN_POWERUPS_KEY:
			respawn_powerups()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			spawn_object(TARGET_SCENE, true)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			spawn_object(ENEMY_SCENE, true)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			spawn_object(CRATE_SCENE)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_4:
			spawn_object(BOULDER_SCENE)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_5:
			spawn_object(KEY_SCENE)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_6:
			spawn_object(LOCK_BOX_SCENE)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_7:
			spawn_object(SPIKES_SCENE)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_8:
			spawn_object(PLATFORM_SCENE)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_9:
			spawn_object(DYNAMITE_SCENE)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_X:
			remove_spawned_object_at_mouse()
			get_viewport().set_input_as_handled()


func target_down(target: Node) -> void:
	if is_respawning:
		return

	var target_index := targets.find(target)
	if target_index >= 0:
		targets.remove_at(target_index)
	targets_left = targets.size()


func respawn_destroyables_and_enemies() -> void:
	if is_respawning:
		return

	is_respawning = true
	for node in _get_live_respawnables():
		node.queue_free()

	await get_tree().process_frame

	targets.clear()
	for record in spawn_records:
		var parent := get_node_or_null(record.parent_path)
		var template := record.template as Node
		if parent == null or template == null:
			continue

		var respawned := template.duplicate(DUPLICATE_FLAGS)
		respawned.name = record.name
		parent.add_child(respawned)
		parent.move_child(respawned, mini(record.index, parent.get_child_count() - 1))
		_register_target(respawned)

	num_targets = targets.size()
	targets_left = num_targets
	has_targets = num_targets > 0
	is_level_transition_queued = false
	is_respawning = false


func refill_bullets() -> void:
	var chamber := get_node_or_null("CanvasLayer/Chamber")
	if chamber != null and chamber.has_method("refill_bullets"):
		chamber.refill_bullets()


func respawn_powerups() -> void:
	if is_respawning_powerups:
		return

	is_respawning_powerups = true
	for powerup in get_tree().get_nodes_in_group(PLAYGROUND_POWERUP_GROUP):
		powerup.queue_free()

	await get_tree().process_frame

	for record in powerup_spawn_records:
		var parent := get_node_or_null(record.parent_path)
		var template := record.template as Node
		if parent == null or template == null:
			continue

		var powerup := template.duplicate(DUPLICATE_FLAGS)
		powerup.name = record.name
		parent.add_child(powerup)
		parent.move_child(powerup, mini(record.index, parent.get_child_count() - 1))

	is_respawning_powerups = false


func spawn_object(scene: PackedScene, is_target := false) -> void:
	var spawned_object := scene.instantiate() as Node2D
	add_child(spawned_object)
	spawned_object.global_position = get_global_mouse_position()
	spawned_object.add_to_group(PLAYGROUND_SPAWNED_OBJECT_GROUP)
	if is_target:
		_register_target(spawned_object)


func remove_spawned_object_at_mouse() -> void:
	var spawned_object := _get_spawned_object_at_mouse()
	if spawned_object == null:
		return

	var target_index := targets.find(spawned_object)
	if target_index >= 0:
		targets.remove_at(target_index)
		targets_left = targets.size()
		num_targets = targets_left

	spawned_object.queue_free()


func _get_spawned_object_at_mouse() -> Node2D:
	var mouse_position := get_global_mouse_position()
	for spawned_object in get_tree().get_nodes_in_group(PLAYGROUND_SPAWNED_OBJECT_GROUP):
		var object_node := spawned_object as Node2D
		if object_node == null:
			continue

		var sprites := object_node.find_children("*", "Sprite2D", true, false)
		var sprite := sprites.front() as Sprite2D
		if sprite != null and sprite.texture != null and sprite.get_rect().has_point(sprite.to_local(mouse_position)):
			return object_node

	return null


func _capture_spawn_records() -> void:
	spawn_records.clear()
	for node in find_children("*", "Node", true, false):
		if _is_respawnable(node):
			spawn_records.append({
				"parent_path": get_path_to(node.get_parent()),
				"index": node.get_index(),
				"name": node.name,
				"template": node.duplicate(DUPLICATE_FLAGS),
			})


func _capture_powerup_spawn_records() -> void:
	powerup_spawn_records.clear()
	for powerup in powerups:
		if powerup == null:
			continue

		powerup.add_to_group(PLAYGROUND_POWERUP_GROUP)
		powerup_spawn_records.append({
			"parent_path": get_path_to(powerup.get_parent()),
			"index": powerup.get_index(),
			"name": powerup.name,
			"template": powerup.duplicate(DUPLICATE_FLAGS),
		})


func _get_live_respawnables() -> Array[Node]:
	var live_nodes: Array[Node] = []
	for node in find_children("*", "Node", true, false):
		if _is_respawnable(node):
			live_nodes.append(node)
	return live_nodes


func _is_respawnable(node: Node) -> bool:
	return node.is_in_group("enemy") or node.is_in_group("breakable")


func _register_target(node: Node) -> void:
	targets.append(node)
	if node.has_signal("target_destroyed") and not node.is_connected("target_destroyed", target_down):
		node.connect("target_destroyed", target_down)

extends TileMapLayer

@export var default_ignite_tolerance: float = 6.0
@export var connected_dynamites: Array[NodePath] = []
@export var dynamite_tile_atlas_coords: Array[Vector2i] = [
	Vector2i(2, 2),
	Vector2i(3, 2),
	Vector2i(1, 3),
]
@export var dynamite_connection_distance: float = 24.0

@onready var ignite_audio: AudioStreamPlayer = $Ignite

const DYNAMITE_SCENE := preload("res://Scenes/Objects/Dynamite.tscn")

var has_ignited := false

func _ready() -> void:
	add_to_group("fuse")

func ignite_by_bullet(hit_position: Vector2, ignite_tolerance: float = default_ignite_tolerance) -> bool:
	var cell: Vector2i = local_to_map(to_local(hit_position))
	if get_cell_source_id(cell) == -1:
		cell = _find_ignite_cell_for_point(hit_position, ignite_tolerance)
		if get_cell_source_id(cell) == -1:
			return false

	_ignite_all_fuses(cell)
	return true

func ignite_along_segment(segment_start: Vector2, segment_end: Vector2, ignite_tolerance: float = default_ignite_tolerance) -> bool:
	var ignite_cell: Vector2i = _find_ignite_cell_along_segment(segment_start, segment_end, ignite_tolerance)
	if get_cell_source_id(ignite_cell) == -1:
		return false

	_ignite_all_fuses(ignite_cell)
	return true

func _ignite_all_fuses(ignite_cell: Vector2i) -> void:
	if has_ignited:
		return

	has_ignited = true
	var parent_node: Node = get_parent()
	var connected_cells := _get_connected_cells(ignite_cell)
	var dynamite_tile_positions := _get_dynamite_tile_positions(connected_cells)
	var nearby_dynamites := _get_nearby_dynamites(dynamite_tile_positions)

	_play_ignite_sound(parent_node)

	for cell: Vector2i in get_used_cells():
		erase_cell(cell)

	for dynamite_path: NodePath in connected_dynamites:
		var dynamite := get_node_or_null(dynamite_path)
		if dynamite != null and dynamite.has_method("explode"):
			dynamite.explode()

	for dynamite: Node in nearby_dynamites:
		if dynamite != null and dynamite.has_method("explode"):
			dynamite.explode()

	for tile_position: Vector2 in dynamite_tile_positions:
		_spawn_dynamite_explosion(parent_node, tile_position)

func _get_connected_cells(start_cell: Vector2i) -> Array[Vector2i]:
	var connected_cells: Array[Vector2i] = []
	var pending_cells: Array[Vector2i] = [start_cell]

	while not pending_cells.is_empty():
		var cell: Vector2i = pending_cells.pop_front()
		if connected_cells.has(cell):
			continue
		if get_cell_source_id(cell) == -1:
			continue

		connected_cells.append(cell)
		for neighbor: Vector2i in [
			cell + Vector2i.LEFT,
			cell + Vector2i.RIGHT,
			cell + Vector2i.UP,
			cell + Vector2i.DOWN,
		]:
			if connected_cells.has(neighbor):
				continue
			if get_cell_source_id(neighbor) == -1:
				continue
			pending_cells.append(neighbor)

	return connected_cells

func _get_dynamite_tile_positions(cells: Array[Vector2i]) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for cell: Vector2i in cells:
		if not dynamite_tile_atlas_coords.has(get_cell_atlas_coords(cell)):
			continue
		positions.append(to_global(map_to_local(cell)))

	return positions

func _spawn_dynamite_explosion(parent_node: Node, spawn_position: Vector2) -> void:
	if parent_node == null:
		return

	var dynamite := DYNAMITE_SCENE.instantiate()
	parent_node.add_child(dynamite)
	if dynamite is Node2D:
		(dynamite as Node2D).global_position = spawn_position
	if dynamite.has_method("explode"):
		dynamite.explode()

func _get_nearby_dynamites(dynamite_tile_positions: Array[Vector2]) -> Array[Node]:
	var nearby_dynamites: Array[Node] = []
	if dynamite_tile_positions.is_empty():
		return nearby_dynamites

	for dynamite: Node in get_tree().get_nodes_in_group("dynamite"):
		if not (dynamite is Node2D):
			continue

		for dynamite_tile_position: Vector2 in dynamite_tile_positions:
			if (dynamite as Node2D).global_position.distance_to(dynamite_tile_position) > dynamite_connection_distance:
				continue
			nearby_dynamites.append(dynamite)
			break

	return nearby_dynamites

func _find_ignite_cell_for_point(hit_position: Vector2, ignite_tolerance: float) -> Vector2i:
	for cell: Vector2i in get_used_cells():
		if _point_intersects_cell(to_local(hit_position), cell, ignite_tolerance):
			return cell

	return Vector2i(-1, -1)

func _find_ignite_cell_along_segment(segment_start: Vector2, segment_end: Vector2, ignite_tolerance: float) -> Vector2i:
	var local_start: Vector2 = to_local(segment_start)
	var local_end: Vector2 = to_local(segment_end)
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_distance: float = INF

	for cell: Vector2i in get_used_cells():
		if not _segment_intersects_cell(local_start, local_end, cell, ignite_tolerance):
			continue

		var cell_center: Vector2 = map_to_local(cell)
		var distance_to_start: float = local_start.distance_to(cell_center)
		if distance_to_start < best_distance:
			best_distance = distance_to_start
			best_cell = cell

	return best_cell

func _point_intersects_cell(local_point: Vector2, cell: Vector2i, ignite_tolerance: float) -> bool:
	return _get_cell_rect(cell, ignite_tolerance).has_point(local_point)

func _segment_intersects_cell(local_start: Vector2, local_end: Vector2, cell: Vector2i, ignite_tolerance: float) -> bool:
	var rect: Rect2 = _get_cell_rect(cell, ignite_tolerance)
	if rect.has_point(local_start) or rect.has_point(local_end):
		return true

	var delta: Vector2 = local_end - local_start
	var t_min: float = 0.0
	var t_max: float = 1.0

	var x_clip: Array = _clip_segment_axis(local_start.x, delta.x, rect.position.x, rect.end.x, t_min, t_max)
	if not x_clip[0]:
		return false
	t_min = x_clip[1]
	t_max = x_clip[2]

	var y_clip: Array = _clip_segment_axis(local_start.y, delta.y, rect.position.y, rect.end.y, t_min, t_max)
	if not y_clip[0]:
		return false
	t_min = y_clip[1]
	t_max = y_clip[2]

	return t_max >= t_min

func _clip_segment_axis(start: float, delta: float, min_bound: float, max_bound: float, t_min: float, t_max: float) -> Array:
	if is_zero_approx(delta):
		return [start >= min_bound and start <= max_bound, t_min, t_max]

	var inverse_delta: float = 1.0 / delta
	var near_time: float = (min_bound - start) * inverse_delta
	var far_time: float = (max_bound - start) * inverse_delta

	if near_time > far_time:
		var swap_time: float = near_time
		near_time = far_time
		far_time = swap_time

	t_min = maxf(t_min, near_time)
	t_max = minf(t_max, far_time)
	return [t_max >= t_min, t_min, t_max]

func _get_cell_rect(cell: Vector2i, ignite_tolerance: float) -> Rect2:
	var center: Vector2 = map_to_local(cell)
	var cell_size: Vector2 = _get_cell_size_local()
	var rect_position: Vector2 = center - cell_size * 0.5 - Vector2.ONE * ignite_tolerance
	var rect_size: Vector2 = cell_size + Vector2.ONE * ignite_tolerance * 2.0
	return Rect2(rect_position, rect_size)

func _get_cell_size_local() -> Vector2:
	var origin: Vector2 = map_to_local(Vector2i.ZERO)
	var right: Vector2 = map_to_local(Vector2i.RIGHT)
	var down: Vector2 = map_to_local(Vector2i.DOWN)
	var width: float = absf(right.x - origin.x)
	var height: float = absf(down.y - origin.y)
	return Vector2(maxf(width, 1.0), maxf(height, 1.0))

func _play_ignite_sound(parent_node: Node) -> void:
	if not is_instance_valid(ignite_audio) or ignite_audio.stream == null:
		return
	if parent_node == null:
		return

	var detached_audio := AudioStreamPlayer.new()
	detached_audio.stream = ignite_audio.stream
	detached_audio.bus = ignite_audio.bus
	parent_node.add_child(detached_audio)
	_configure_audio_for_bullet_time(detached_audio)
	detached_audio.finished.connect(detached_audio.queue_free)
	detached_audio.play()

func _configure_audio_for_bullet_time(audio_player: AudioStreamPlayer) -> void:
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("configure_audio_player_for_bullet_time"):
		game_manager.configure_audio_player_for_bullet_time(audio_player)

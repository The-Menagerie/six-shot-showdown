extends TileMapLayer

@export var default_cut_tolerance: float = 6.0

const CRATE_TILE_COORDS := Vector2i(2, 0)
const BOULDER_TILE_COORDS := Vector2i(3, 0)
const CRATE_SCENE := preload("res://Scenes/Objects/Breakables/crate.tscn")
const BOULDER_SCENE := preload("res://Scenes/Objects/Boulder.tscn")

@onready var break_audio: AudioStreamPlayer = $Break

func _ready() -> void:
	add_to_group("rope")

func cut_by_bullet(hit_position: Vector2, cut_tolerance: float = default_cut_tolerance) -> bool:
	var cell: Vector2i = local_to_map(to_local(hit_position))
	if get_cell_source_id(cell) == -1:
		cell = _find_cut_cell_for_point(hit_position, cut_tolerance)
		if get_cell_source_id(cell) == -1:
			return false

	_break_all_rope()
	return true

func cut_along_segment(segment_start: Vector2, segment_end: Vector2, cut_tolerance: float = default_cut_tolerance) -> bool:
	var cut_cell: Vector2i = _find_cut_cell_along_segment(segment_start, segment_end, cut_tolerance)
	if get_cell_source_id(cut_cell) == -1:
		return false
	
	if get_cell_atlas_coords(cut_cell) == Vector2i(2,0) or get_cell_atlas_coords(cut_cell) == Vector2i(3,0):
		return false

	_break_all_rope()
	return true

func _break_all_rope() -> void:
	var parent_node: Node = get_parent()
	_play_break_sound(parent_node)
	var cells_to_break: Array[Vector2i] = get_used_cells()
	for cell: Vector2i in cells_to_break:
		_spawn_hanging_object_for_cell(parent_node, cell)
		erase_cell(cell)

func _spawn_hanging_object_for_cell(parent_node: Node, cell: Vector2i) -> void:
	if parent_node == null:
		return

	var atlas_coords: Vector2i = get_cell_atlas_coords(cell)
	var spawned_node: Node2D = null

	if atlas_coords == CRATE_TILE_COORDS:
		spawned_node = CRATE_SCENE.instantiate() as Node2D
	elif atlas_coords == BOULDER_TILE_COORDS:
		spawned_node = BOULDER_SCENE.instantiate() as Node2D

	if spawned_node == null:
		return

	parent_node.add_child(spawned_node)
	spawned_node.global_position = to_global(map_to_local(cell))

func _find_cut_cell_for_point(hit_position: Vector2, cut_tolerance: float) -> Vector2i:
	for cell: Vector2i in get_used_cells():
		if _point_intersects_cell(to_local(hit_position), cell, cut_tolerance):
			return cell

	return Vector2i(-1, -1)

func _find_cut_cell_along_segment(segment_start: Vector2, segment_end: Vector2, cut_tolerance: float) -> Vector2i:
	var local_start: Vector2 = to_local(segment_start)
	var local_end: Vector2 = to_local(segment_end)
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_distance: float = INF

	for cell: Vector2i in get_used_cells():
		if not _segment_intersects_cell(local_start, local_end, cell, cut_tolerance):
			continue

		var cell_center: Vector2 = map_to_local(cell)
		var distance_to_start: float = local_start.distance_to(cell_center)
		if distance_to_start < best_distance:
			best_distance = distance_to_start
			best_cell = cell

	return best_cell

func _point_intersects_cell(local_point: Vector2, cell: Vector2i, cut_tolerance: float) -> bool:
	return _get_cell_rect(cell, cut_tolerance).has_point(local_point)

func _segment_intersects_cell(local_start: Vector2, local_end: Vector2, cell: Vector2i, cut_tolerance: float) -> bool:
	var rect: Rect2 = _get_cell_rect(cell, cut_tolerance)
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

func _get_cell_rect(cell: Vector2i, cut_tolerance: float) -> Rect2:
	var center: Vector2 = map_to_local(cell)
	var cell_size: Vector2 = _get_cell_size_local()
	var rect_position: Vector2 = center - cell_size * 0.5 - Vector2.ONE * cut_tolerance
	var rect_size: Vector2 = cell_size + Vector2.ONE * cut_tolerance * 2.0
	return Rect2(rect_position, rect_size)

func _get_cell_size_local() -> Vector2:
	var origin: Vector2 = map_to_local(Vector2i.ZERO)
	var right: Vector2 = map_to_local(Vector2i.RIGHT)
	var down: Vector2 = map_to_local(Vector2i.DOWN)
	var width: float = absf(right.x - origin.x)
	var height: float = absf(down.y - origin.y)
	return Vector2(maxf(width, 1.0), maxf(height, 1.0))

func _play_break_sound(parent_node: Node) -> void:
	if not is_instance_valid(break_audio) or break_audio.stream == null:
		return
	if parent_node == null:
		return

	var detached_audio := AudioStreamPlayer.new()
	detached_audio.stream = break_audio.stream
	detached_audio.bus = break_audio.bus
	parent_node.add_child(detached_audio)
	_configure_audio_for_bullet_time(detached_audio)
	detached_audio.finished.connect(detached_audio.queue_free)
	detached_audio.play()

func _configure_audio_for_bullet_time(audio_player: AudioStreamPlayer) -> void:
	var game_manager := get_tree().root.find_child("MainGame", true, false)
	if game_manager != null and game_manager.has_method("configure_audio_player_for_bullet_time"):
		game_manager.configure_audio_player_for_bullet_time(audio_player)

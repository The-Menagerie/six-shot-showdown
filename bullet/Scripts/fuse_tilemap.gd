extends TileMapLayer

@export var default_ignite_tolerance: float = 6.0
@export var connected_dynamites: Array[NodePath] = []
@export var dynamite_tile_atlas_coords: Array[Vector2i] = [
	Vector2i(0, 3),
	Vector2i(1, 3),
]
@export var dynamite_connection_distance: float = 24.0
@export var trigger_tile_atlas_coords: Array[Vector2i] = [
	Vector2i(0, 4),
]
@export var trigger_outline_atlas_coords := Vector2i(2, 4)
@export var spent_trigger_atlas_coords := Vector2i(1, 4)
@export var trigger_interaction_size := Vector2(24, 24)
@export var dynamite_player_explosion_impulse: float = 150.0
@export var dynamite_player_explosion_radius: float = 96.0
@export var dynamite_player_explosion_horizontal_scale: float = 0.25
@export var dynamite_player_explosion_upward_bias: float = 0.85
@export var trigger_player_launch_radius: float = 96.0

@onready var ignite_audio: AudioStreamPlayer = $Ignite
@onready var connector_layer: TileMapLayer = get_node_or_null("Connectors")

const DYNAMITE_SCENE := preload("res://Scenes/Objects/Dynamite.tscn")

var has_ignited := false
var trigger_areas: Dictionary[Vector2i, Area2D] = {}
var trigger_outlines: Dictionary[Vector2i, Sprite2D] = {}

func _ready() -> void:
	add_to_group("fuse")
	_create_trigger_interactions()

# Both painting layers share the same grid and form one fuse network.
func _get_fuse_layers() -> Array[TileMapLayer]:
	var layers: Array[TileMapLayer] = [self]
	if is_instance_valid(connector_layer):
		layers.append(connector_layer)
	return layers

func _get_used_fuse_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = get_used_cells()
	if is_instance_valid(connector_layer):
		for cell: Vector2i in connector_layer.get_used_cells():
			if not cells.has(cell):
				cells.append(cell)
	return cells

func _has_fuse_cell(cell: Vector2i) -> bool:
	for layer: TileMapLayer in _get_fuse_layers():
		if layer.get_cell_source_id(cell) != -1:
			return true
	return false

func _create_trigger_interactions() -> void:
	for cell: Vector2i in get_used_cells():
		if not trigger_tile_atlas_coords.has(get_cell_atlas_coords(cell)):
			continue
		var source := tile_set.get_source(get_cell_source_id(cell)) as TileSetAtlasSource
		if source == null:
			continue

		var area := Area2D.new()
		area.position = map_to_local(cell)
		area.collision_layer = 0
		area.collision_mask = 1
		area.monitorable = false
		var shape := RectangleShape2D.new()
		shape.size = trigger_interaction_size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		area.add_child(collision)
		add_child(area)
		trigger_areas[cell] = area

		var outline_texture := AtlasTexture.new()
		outline_texture.atlas = source.texture
		outline_texture.region = Rect2(
			Vector2(source.margins + trigger_outline_atlas_coords * (source.texture_region_size + source.separation)),
			Vector2(source.texture_region_size)
		)
		var outline := Sprite2D.new()
		outline.texture = outline_texture
		outline.z_index = 4
		outline.visible = false
		area.add_child(outline)
		trigger_outlines[cell] = outline

func _physics_process(_delta: float) -> void:
	if has_ignited:
		return
	for cell: Vector2i in trigger_areas:
		trigger_outlines[cell].visible = _can_interact_with_trigger(cell)

func _can_interact_with_trigger(cell: Vector2i) -> bool:
	if has_ignited or not is_visible_in_tree():
		return false
	for body: Node2D in trigger_areas[cell].get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	for cell: Vector2i in trigger_areas:
		if _can_interact_with_trigger(cell):
			get_viewport().set_input_as_handled()
			_launch_players_from_trigger(cell)
			_ignite_all_fuses(cell)
			return

func ignite_by_bullet(hit_position: Vector2, ignite_tolerance: float = default_ignite_tolerance) -> bool:
	if has_ignited:
		return false
	var cell: Vector2i = local_to_map(to_local(hit_position))
	if not _has_fuse_cell(cell):
		cell = _find_ignite_cell_for_point(hit_position, ignite_tolerance)
		if not _has_fuse_cell(cell):
			return false
	if _is_trigger_cell(cell):
		return false

	_ignite_all_fuses(cell)
	return true

func ignite_along_segment(segment_start: Vector2, segment_end: Vector2, ignite_tolerance: float = default_ignite_tolerance) -> bool:
	if has_ignited:
		return false
	var ignite_cell: Vector2i = _find_ignite_cell_along_segment(segment_start, segment_end, ignite_tolerance)
	if not _has_fuse_cell(ignite_cell):
		return false
	if _is_trigger_cell(ignite_cell):
		return false

	_ignite_all_fuses(ignite_cell)
	return true

func ignite_by_explosion(explosion_position: Vector2, explosion_radius: float) -> bool:
	if has_ignited or explosion_radius < 0.0:
		return false
	for cell: Vector2i in _get_used_fuse_cells():
		var rect := _get_fuse_connection_rect(cell)
		# Check in world space so rotated and scaled Fuse instances use the blast radius correctly.
		var corners := PackedVector2Array([
			to_global(rect.position),
			to_global(Vector2(rect.end.x, rect.position.y)),
			to_global(rect.end),
			to_global(Vector2(rect.position.x, rect.end.y)),
		])
		var touches_blast := Geometry2D.is_point_in_polygon(explosion_position, corners)
		for edge in range(4):
			var closest := Geometry2D.get_closest_point_to_segment(explosion_position, corners[edge], corners[(edge + 1) % 4])
			if explosion_position.distance_squared_to(closest) <= explosion_radius * explosion_radius:
				touches_blast = true
				break
		if touches_blast:
			_ignite_all_fuses(cell)
			return true
	return false

func _ignite_all_fuses(ignite_cell: Vector2i) -> void:
	if has_ignited:
		return

	has_ignited = true
	remove_from_group("fuse")
	set_physics_process(false)
	set_process_unhandled_input(false)
	for area: Area2D in trigger_areas.values():
		area.hide()
		area.queue_free()
	trigger_areas.clear()
	trigger_outlines.clear()
	var parent_node: Node = get_parent()
	var connected_cells := _get_connected_cells(ignite_cell)
	var dynamite_tile_positions := _get_dynamite_tile_positions(connected_cells)
	var nearby_dynamites := _get_nearby_dynamites(dynamite_tile_positions)

	_play_ignite_sound(parent_node)

	for layer: TileMapLayer in _get_fuse_layers():
		for cell: Vector2i in layer.get_used_cells():
			if trigger_tile_atlas_coords.has(layer.get_cell_atlas_coords(cell)):
				layer.set_cell(cell, layer.get_cell_source_id(cell), spent_trigger_atlas_coords, layer.get_cell_alternative_tile(cell))
			else:
				layer.erase_cell(cell)

	for dynamite_path: NodePath in connected_dynamites:
		var dynamite := get_node_or_null(dynamite_path)
		if dynamite != null and dynamite.has_method("explode"):
			_configure_dynamite_player_launch(dynamite)
			dynamite.explode()

	for dynamite: Node in nearby_dynamites:
		if dynamite != null and dynamite.has_method("explode"):
			_configure_dynamite_player_launch(dynamite)
			dynamite.explode()

	for tile_position: Vector2 in dynamite_tile_positions:
		_spawn_dynamite_explosion(parent_node, tile_position)

func _get_connected_cells(start_cell: Vector2i) -> Array[Vector2i]:
	var connected_cells: Array[Vector2i] = []
	var pending_cells: Array[Vector2i] = [start_cell]
	var cell_rects: Dictionary[Vector2i, Rect2] = {}
	for cell: Vector2i in _get_used_fuse_cells():
		cell_rects[cell] = _get_fuse_connection_rect(cell)

	while not pending_cells.is_empty():
		var cell: Vector2i = pending_cells.pop_front()
		if connected_cells.has(cell):
			continue
		if not _has_fuse_cell(cell):
			continue

		connected_cells.append(cell)
		for neighbor: Vector2i in cell_rects:
			if connected_cells.has(neighbor) or pending_cells.has(neighbor):
				continue
			var rect: Rect2 = cell_rects[cell]
			var neighbor_rect: Rect2 = cell_rects[neighbor]
			var overlap := rect.end.min(neighbor_rect.end) - rect.position.max(neighbor_rect.position)
			# Follow overlapping or edge-touching artwork, even on a smaller tile grid.
			# A corner alone does not connect two fuse pieces.
			if overlap.x < 0.0 or overlap.y < 0.0 or overlap == Vector2.ZERO:
				continue
			pending_cells.append(neighbor)

	return connected_cells

func _get_fuse_connection_rect(cell: Vector2i) -> Rect2:
	var rect := Rect2()
	var has_rect := false
	for layer: TileMapLayer in _get_fuse_layers():
		if layer.get_cell_source_id(cell) == -1:
			continue
		var layer_rect := _get_layer_connection_rect(layer, cell)
		rect = rect.merge(layer_rect) if has_rect else layer_rect
		has_rect = true
	return rect

func _get_layer_connection_rect(layer: TileMapLayer, cell: Vector2i) -> Rect2:
	var size := _get_cell_size_local()
	var center := map_to_local(cell)
	var source := layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
	if source != null:
		var atlas_coords := layer.get_cell_atlas_coords(cell)
		size = Vector2(source.texture_region_size * source.get_tile_size_in_atlas(atlas_coords))
		var tile_data := layer.get_cell_tile_data(cell)
		if tile_data != null:
			if tile_data.transpose:
				size = Vector2(size.y, size.x)
			center -= Vector2(tile_data.texture_origin)
	return Rect2(center - size * 0.5, size)

func _get_dynamite_tile_positions(cells: Array[Vector2i]) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for cell: Vector2i in cells:
		for layer: TileMapLayer in _get_fuse_layers():
			if dynamite_tile_atlas_coords.has(layer.get_cell_atlas_coords(cell)):
				positions.append(to_global(map_to_local(cell)))
				break

	return positions

func _is_trigger_cell(cell: Vector2i) -> bool:
	return trigger_tile_atlas_coords.has(get_cell_atlas_coords(cell))

func _configure_dynamite_player_launch(dynamite: Node) -> void:
	if "player_explosion_impulse" in dynamite:
		dynamite.player_explosion_impulse = dynamite_player_explosion_impulse
	if "player_explosion_radius" in dynamite:
		dynamite.player_explosion_radius = dynamite_player_explosion_radius
	if "player_explosion_horizontal_scale" in dynamite:
		dynamite.player_explosion_horizontal_scale = dynamite_player_explosion_horizontal_scale
	if "player_explosion_upward_bias" in dynamite:
		dynamite.player_explosion_upward_bias = dynamite_player_explosion_upward_bias

func _launch_players_from_trigger(cell: Vector2i) -> void:
	var launch_origin := to_global(map_to_local(cell))
	var radius_squared := trigger_player_launch_radius * trigger_player_launch_radius
	for player in get_tree().get_nodes_in_group("player"):
		if not (player is Node2D):
			continue
		if launch_origin.distance_squared_to((player as Node2D).global_position) > radius_squared:
			continue

		var impulse := _get_player_launch_impulse(launch_origin, (player as Node2D).global_position)
		if player.has_method("apply_explosion_knockback"):
			player.apply_explosion_knockback(impulse)

func _get_player_launch_impulse(launch_origin: Vector2, player_position: Vector2) -> Vector2:
	var launch_direction := player_position - launch_origin
	if launch_direction == Vector2.ZERO:
		launch_direction = Vector2.UP

	launch_direction = launch_direction.normalized()
	launch_direction.x *= dynamite_player_explosion_horizontal_scale
	launch_direction.y = minf(launch_direction.y, -dynamite_player_explosion_upward_bias)
	return launch_direction.normalized() * dynamite_player_explosion_impulse

func _spawn_dynamite_explosion(parent_node: Node, spawn_position: Vector2) -> void:
	if parent_node == null:
		return

	call_deferred("_finish_spawn_dynamite_explosion", parent_node, spawn_position)

func _finish_spawn_dynamite_explosion(parent_node: Node, spawn_position: Vector2) -> void:
	if not is_instance_valid(parent_node):
		return

	var dynamite := DYNAMITE_SCENE.instantiate()
	parent_node.add_child(dynamite)
	if dynamite is Node2D:
		(dynamite as Node2D).global_position = spawn_position
	_configure_dynamite_player_launch(dynamite)
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
	for cell: Vector2i in _get_used_fuse_cells():
		if _point_intersects_cell(to_local(hit_position), cell, ignite_tolerance):
			return cell

	return Vector2i(-1, -1)

func _find_ignite_cell_along_segment(segment_start: Vector2, segment_end: Vector2, ignite_tolerance: float) -> Vector2i:
	var local_start: Vector2 = to_local(segment_start)
	var local_end: Vector2 = to_local(segment_end)
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_distance: float = INF

	for cell: Vector2i in _get_used_fuse_cells():
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

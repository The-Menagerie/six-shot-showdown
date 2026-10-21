class_name BulletTrail
extends Node2D

const MIN_POINT_DISTANCE: float = 0.5

@export var trail_color: Color = Color(1.0, 0.85, 0.4, 0.9):
	set(value):
		trail_color = value
		_apply_color()

@export_range(0.0, 128.0, 0.5, "suffix:px") var trail_width: float = 4.0:
	set(value):
		trail_width = maxf(value, 0.0)
		_apply_geometry()

@export_range(0.0, 4096.0, 1.0, "suffix:px") var trail_length: float = 96.0:
	set(value):
		trail_length = maxf(value, 0.0)
		_apply_geometry()

@export var trail_enabled: bool = true:
	set(value):
		trail_enabled = value
		_refresh_visibility()

## Additive blending makes the tracer glow.
@export var additive_blend: bool = true:
	set(value):
		additive_blend = value
		_apply_blend_mode()

## Lets the trail catch up if the bullet goes too far
@export_range(0.0, 1024.0, 1.0, "suffix:px") var teleport_threshold: float = 64.0

## Time it takes for the trail to disappear after the bullet is destroyed
@export_range(0.0, 1.0, 0.01, "suffix:s") var fade_out_duration: float = 0.12

## Bullet offset
@export var follow_offset: Vector2 = Vector2.ZERO

var _bullet: Node2D = null
var _line: Line2D = null
var _gradient: Gradient = null
var _width_curve: Curve = null

var _points: PackedVector2Array = PackedVector2Array()
var _last_world_point: Vector2 = Vector2.ZERO
var _has_last_world_point: bool = false

var _detached: bool = false
var _fading_out: bool = false
var _fade_time_left: float = 0.0
var _fade_duration: float = 0.0


func _ready() -> void:
	if _bullet == null:
		_bullet = get_parent() as Node2D
	if _bullet == null:
		push_warning("BulletTrail must be a child of a Node2D.")
		set_process(false)
		return

	_build_line()
	_apply_runtime_settings()

	# Prevents trail from vanishing when bullet hits a thing.
	call_deferred("_detach_from_bullet")


func _process(delta: float) -> void:
	if _fading_out:
		_fade_time_left -= delta
		if _line != null:
			_line.modulate.a = clampf(_fade_time_left / maxf(_fade_duration, 0.0001), 0.0, 1.0)
		if _fade_time_left <= 0.0:
			queue_free()
		return

	if not is_instance_valid(_bullet):
		_begin_fade_out()
		return

	var world_point: Vector2 = _bullet.global_position + follow_offset.rotated(_bullet.global_rotation)
	_record_point(world_point)


## If the bullet couldn't be found on _ready()
func bind_bullet(bullet: Node2D) -> void:
	_bullet = bullet

func _build_line() -> void:
	_line = Line2D.new()
	_line.name = "TrailLine"
	_line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.round_precision = 8
	_line.antialiased = true
	_line.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_line.texture = _create_edge_texture()

	# The gradient runs from the tail (offset 0) to the bullet (offset 1).
	_gradient = Gradient.new()
	_gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	_gradient.colors = PackedColorArray([
		Color(trail_color.r, trail_color.g, trail_color.b, 0.0),
		Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a * 0.5),
		trail_color,
	])
	_line.gradient = _gradient

	# The width curve also runs tail to bullet, multiplying trail_width.
	_width_curve = Curve.new()
	_width_curve.add_point(Vector2(0.0, 0.02))
	_width_curve.add_point(Vector2(0.35, 0.35))
	_width_curve.add_point(Vector2(1.0, 1.0))
	_line.width_curve = _width_curve

	_apply_blend_mode()
	add_child(_line)


func _create_edge_texture() -> GradientTexture2D:
	#Makes the gradiant of the more transparent color on the lateral edges of the trail
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.28, 0.5, 0.72, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.35),
		Color.WHITE,
		Color(1.0, 1.0, 1.0, 0.35),
		Color(1.0, 1.0, 1.0, 0.0),
	])

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 8
	texture.height = 64
	return texture


func _apply_runtime_settings() -> void:
	_apply_color()
	_apply_blend_mode()
	_apply_geometry()
	_refresh_visibility()


func _apply_color() -> void:
	if _gradient == null:
		return

	var middle := trail_color
	middle.a *= 0.5
	var tail := trail_color
	tail.a = 0.0

	_gradient.set_color(0, tail)
	_gradient.set_color(1, middle)
	_gradient.set_color(2, trail_color)


func _apply_blend_mode() -> void:
	if _line == null:
		return

	var canvas_material := CanvasItemMaterial.new()
	canvas_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD if additive_blend else CanvasItemMaterial.BLEND_MODE_MIX
	canvas_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_line.material = canvas_material


func _apply_geometry() -> void:
	if _line == null:
		return

	_line.width = trail_width
	_trim_points()
	_line.points = _points
	_refresh_visibility()


func _refresh_visibility() -> void:
	if _line == null:
		return
	_line.visible = trail_enabled and trail_width > 0.0 and trail_length > 0.0


func _record_point(world_point: Vector2) -> void:
	if _line == null:
		return

	var local_point := to_local(world_point)

	# If the bullet jumps too far for some reason like a bug.
	if _has_last_world_point and world_point.distance_to(_last_world_point) > teleport_threshold:
		_points.clear()
		_points.append(local_point)
		_last_world_point = world_point
		_has_last_world_point = true
		_line.points = _points
		return

	_last_world_point = world_point
	_has_last_world_point = true

	if _points.is_empty():
		_points.append(local_point)
	elif _points[_points.size() - 1].distance_to(local_point) >= MIN_POINT_DISTANCE:
		_points.append(local_point)
	else:
		# Keep the head exactly on the bullet without adding weird duplicate points.
		_points[_points.size() - 1] = local_point

	_trim_points()
	_line.points = _points


func _trim_points() -> void:
	if trail_length <= 0.0:
		_points.clear()
		return
	if _points.size() < 2:
		return

	var total := _path_length()
	while total > trail_length + 0.001 and _points.size() >= 2:
		var segment := _points[1] - _points[0]
		var segment_length := segment.length()
		var excess := total - trail_length
		if segment_length >= excess:
			
			if segment_length > 0.0001:
				_points[0] = _points[0].lerp(_points[1], excess / segment_length)
			break
		_points.remove_at(0)
		total -= segment_length


func _path_length() -> float:
	var total := 0.0
	for index in range(1, _points.size()):
		total += _points[index].distance_to(_points[index - 1])
	return total


func _detach_from_bullet() -> void:
	if _detached:
		return
	_detached = true

	if not is_instance_valid(_bullet) or get_parent() != _bullet:
		return

	var bullet := _bullet
	var host: Node = bullet.get_parent()
	if host == null:
		host = get_tree().current_scene
	if host == null:
		host = get_tree().root
	if host == null:
		return

	reparent(host, true)
	_points.clear()
	if _line != null:
		_line.points = _points
	_last_world_point = bullet.global_position
	_has_last_world_point = true


func _begin_fade_out() -> void:
	if _fading_out:
		return

	_fading_out = true
	_bullet = null
	_fade_duration = maxf(fade_out_duration, 0.0)
	_fade_time_left = _fade_duration
	_refresh_visibility()
	if _fade_duration <= 0.0:
		queue_free()

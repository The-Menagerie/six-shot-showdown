extends "res://Scripts/Classes/level_root.gd"

@export_range(0.0, 60.0, 0.5) var key_hint_delay: float = 20.0
@export var key_node: NodePath
@export var key_hint_label: NodePath
@export var key_hint_offset: Vector2 = Vector2(0.0, 32.0)
@export_range(0.0, 32.0, 0.5) var key_hint_hover_amplitude: float = 6.0
@export_range(0.1, 10.0, 0.1) var key_hint_hover_speed: float = 2.0
@export_range(0.05, 3.0, 0.05) var key_hint_fade_duration: float = 0.5

var _key_picked_up := false
var _hint_visible := false

func _ready() -> void:
	super._ready()

	var key := get_node_or_null(key_node)
	if key != null and key.has_signal("picked_up"):
		key.picked_up.connect(_on_key_picked_up)

	var hint_label := get_node_or_null(key_hint_label) as Label
	if hint_label != null:
		hint_label.modulate.a = 0.0
		hint_label.hide()

	call_deferred("_watch_for_key_hint")

func _process(_delta: float) -> void:
	if not _hint_visible:
		return

	var key := get_node_or_null(key_node) as Node2D
	var hint_label := get_node_or_null(key_hint_label) as Label
	if not is_instance_valid(key) or hint_label == null:
		return

	var screen_position: Vector2 = get_viewport().get_canvas_transform() * key.global_position
	var label_size: Vector2 = hint_label.get_combined_minimum_size()
	var hover_offset := sin(Time.get_ticks_msec() / 1000.0 * key_hint_hover_speed) * key_hint_hover_amplitude
	hint_label.position = screen_position + key_hint_offset + Vector2(-label_size.x * 0.5, hover_offset)

func _watch_for_key_hint() -> void:
	if key_hint_delay <= 0.0:
		return

	await get_tree().create_timer(key_hint_delay, true, false, true).timeout
	if _key_picked_up:
		return

	var key := get_node_or_null(key_node)
	if not is_instance_valid(key):
		return

	var hint_label := get_node_or_null(key_hint_label) as Label
	if hint_label != null:
		_show_hint_label(hint_label)

func _on_key_picked_up(_by: Node2D) -> void:
	_key_picked_up = true

	var hint_label := get_node_or_null(key_hint_label) as Label
	if hint_label != null:
		_hint_visible = false
		hint_label.hide()

func _show_hint_label(hint_label: Label) -> void:
	_hint_visible = true
	hint_label.modulate.a = 0.0
	hint_label.show()
	_process(0.0)

	var fade_tween := create_tween()
	fade_tween.tween_property(hint_label, "modulate:a", 1.0, key_hint_fade_duration)

@tool
extends Control

enum BULLET_TYPE {REGULAR = 5, RUBBER = 4, PIERCING = 3, FLY = 2, SWAP = 1, SAD = 99, FIRE = 6, KEY = 7, ICE = 8}

const BULLET_NAME_BASE_FONT_SIZE := 14
const CHAMBER_BASE_SIZE := 64.0
const BULLET_NAME_HORIZONTAL_PADDING := 12.0
const BULLET_NAME_MIN_HEIGHT := 24.0

var bullet_change_animation_dictionary = {
	"Bullet1": "bullet_one_change",
	"Bullet2": "bullet_two_change",
	"Bullet3": "bullet_three_change",
	"Bullet4": "bullet_four_change",
	"Bullet5": "bullet_five_change",
	"Bullet6": "bullet_six_change",
}

var bullet_dictionary = {
	5:  {
		bullet_name = "Regular Bullet",
		chamber_scene = "res://Assets/Images/ChamberBullets/regular_bullet.png",
		combat_scene = preload("res://Scenes/Objects/Bullets/bullet.tscn"),
		},
	4: {
		bullet_name = "Rubber Bullet",
		chamber_scene = "res://Assets/Images/ChamberBullets/rubber_bullet.png",
		combat_scene = preload("res://Scenes/Objects/Bullets/rubber_bullet.tscn"),
	},
	3: {
		bullet_name = "Piercing Bullet",
		chamber_scene = "res://Assets/Images/ChamberBullets/piercing_bullet.png",
		combat_scene = preload("res://Scenes/Objects/Bullets/piercing_bullet.tscn"),
	},
	2: {
		bullet_name = "Fly Bullet",
		chamber_scene = "res://Assets/Images/ChamberBullets/fly_bullet.png",
		combat_scene = preload("res://Scenes/Objects/Bullets/fly_bullet.tscn"),
	},
	1: {
		bullet_name = "Swap Bullet",
		chamber_scene = "res://Assets/Images/ChamberBullets/swap_bullet.png",
		combat_scene = preload("res://Scenes/Objects/Bullets/swap_bullet.tscn"),
	},
	6: {
		bullet_name = "Fire Bullet",
		chamber_scene = "res://Assets/Images/ChamberBullets/fire_bullet.png",
		combat_scene = preload("res://Scenes/Objects/Bullets/fire_bullet.tscn"),
	},
	7: {
		bullet_name = "Key Bullet",
		chamber_scene = "res://Assets/Images/ChamberBullets/key_bullet.png",
		combat_scene = preload("res://Scenes/Objects/Bullets/key_bullet.tscn"),
	},
	8: {
		bullet_name = "Ice Bullet",
		chamber_scene = "res://Assets/Images/ChamberBullets/ice_bullet.png",
		combat_scene = preload("res://Scenes/Objects/Bullets/ice_bullet.tscn"),
	},
	99: {
		bullet_name = "Sad Bullet",
		chamber_scene = "res://Assets/Images/ChamberBullets/sad_bullet.png",
		combat_scene = preload("res://Scenes/Objects/Bullets/bullet.tscn"),
	}
}

var chambered_bullet_scenes: Array[PackedScene]
var chambered_bullet_names: Array[String]


@export var bullet_pattern: Array[BULLET_TYPE]
@export var bullets: Array[Node]

@export var anim_player: Node
@export var name_changer: Node
@export var bullet_changer: Node
@export var cylinder_rotator: Node

@export var score_cost: int = 100
@export var bullet_name_offset: Vector2 = Vector2(0.0, -2.0)

var cylinder_start_pos
var scale_modifier := 1.0
var chamber_scale_setting := 3.0
var base_alignment_position := Vector2.ZERO
var base_alignment_scale := Vector2.ONE
var bullet_name_changed = false

var to_change_image: Array[String]
var to_change_name:= ""
var original_bullet_templates: Array[Node]
var refill_bullet_pattern: Array[int] = []
var is_refilling := false

@onready var bullet_name_holder: Control = $BulletNameHolder
@onready var bullet_name_text: Label = $BulletNameHolder/BulletName
@onready var cylinder_container = $alignment/VBoxContainer
@onready var alignment: Control = $alignment
@onready var bullet_holder: Control = $alignment/BulletHolder

func _ready() -> void:
	BulletBus.bullet_swap.connect(_change_current_bullet)
	BulletBus.chamber_swap.connect(_change_chamber)
	#var screen_dimensions = get_viewport().get_visible_rect()
	#var screen_x = screen_dimensions.size.x
	#var screen_y = screen_dimensions.size.y
	base_alignment_position = alignment.position
	base_alignment_scale = alignment.scale
	var chamber_scale := 3.0
	if Engine.is_editor_hint():
		chamber_scale = maxf(base_alignment_scale.x, 1.0)
	else:
		chamber_scale = BulletBus.current_chamber_scale
	chamber_scale_setting = chamber_scale
	fit_resolution()
	if not Engine.is_editor_hint() and not BulletBus.force_rescale.is_connected(rescale_to):
		BulletBus.force_rescale.connect(rescale_to)
	anim_player.play_section("RESET")
	refill_bullet_pattern = bullet_pattern.duplicate()
	_load_bullet_pattern()
	_cache_original_bullet_templates()
	change_bullet_name()
	if not Engine.is_editor_hint():
		_emit_out_of_ammo_state()
	_refresh_bullet_name_layout()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		_refresh_bullet_name_layout()
		return
	if is_refilling:
		return

	if Input.is_action_just_pressed("shoot"):
		if chambered_bullet_scenes.size() > 0:
			BulletBus.fire_player_bullet.emit(chambered_bullet_scenes[0])
			ScoreBus.spend_score(score_cost)
			bullets[0].queue_free()
			if anim_player.is_playing():
				anim_player.stop()
				if not chambered_bullet_names.is_empty() && not bullet_name_changed:
					chambered_bullet_names.remove_at(0)
				var distance_partial_rotated = fmod(cylinder_rotator.rotation_degrees,60.0)
				rotate_chamber(60 - distance_partial_rotated)
			anim_player.play_section("revolve")
			chambered_bullet_scenes.remove_at(0)
			bullets.remove_at(0)
			_emit_out_of_ammo_state()
		else:
			print('Oops, looks like yer outta ammo')
			_emit_out_of_ammo_state()

func rotate_chamber(rot_deg: float) -> void:
	cylinder_rotator.rotation_degrees += rot_deg

func shift_chamber_pos(pos_pix_x: float, pos_pix_y: float) -> void:
	cylinder_rotator.position.x += pos_pix_x
	cylinder_rotator.position.y += pos_pix_y

func reset_chamber_pos() -> void:
	cylinder_rotator.position = cylinder_start_pos

func fit_resolution() -> void:
	if Engine.is_editor_hint():
		_apply_chamber_scale()
		return

	var screen_x = self.size.x
	var screen_y = self.size.y
	if (1920.0 - screen_x) > (1080.0 - screen_y):
		scale_modifier = screen_x/1920.0
	elif (1080.0 - screen_y) >= (1920.0 - screen_x):
		scale_modifier = screen_y/1080.0
	_apply_chamber_scale()

func _apply_chamber_scale() -> void:
	var target_scale := chamber_scale_setting * scale_modifier
	alignment.scale = Vector2(target_scale, target_scale)
	alignment.position = base_alignment_position + Vector2(0.0, (base_alignment_scale.x - target_scale) * CHAMBER_BASE_SIZE)
	cylinder_start_pos = cylinder_rotator.position
	_refresh_bullet_name_layout()

func rescale_to(new_scale:float) -> void:
	chamber_scale_setting = new_scale
	_apply_chamber_scale()

func change_bullet_name() -> void:
	if not chambered_bullet_names.is_empty():
		#print(chambered_bullet_names)
		#print(chambered_bullet_names[0])
		bullet_name_text.text = chambered_bullet_names[0]
		chambered_bullet_names.remove_at(0)
		bullet_name_changed = true
	else:
		bullet_name_text.text = ""
	_refresh_bullet_name_layout()

func _emit_out_of_ammo_state() -> void:
	BulletBus.out_of_ammo_changed.emit(chambered_bullet_scenes.is_empty())

func _refresh_bullet_name_layout() -> void:
	if not is_instance_valid(bullet_name_holder):
		return
	if not is_instance_valid(bullet_name_text):
		return
	if not is_instance_valid(alignment):
		return
	if not is_instance_valid(cylinder_container):
		return

	var chamber_scale: float = alignment.scale.x
	var font_size: int = max(1, int(round(BULLET_NAME_BASE_FONT_SIZE * chamber_scale)))
	bullet_name_text.add_theme_font_size_override("font_size", font_size)

	var text_size: Vector2 = bullet_name_text.get_combined_minimum_size()
	var holder_size: Vector2 = Vector2(
		text_size.x + BULLET_NAME_HORIZONTAL_PADDING * 2.0,
		maxf(text_size.y, BULLET_NAME_MIN_HEIGHT * chamber_scale)
	)
	var chamber_rect: Rect2 = cylinder_container.get_global_rect()
	var holder_position: Vector2 = Vector2(
		chamber_rect.position.x + chamber_rect.size.x * 0.5 - holder_size.x * 0.5 + bullet_name_offset.x * chamber_scale,
		chamber_rect.position.y - holder_size.y + bullet_name_offset.y * chamber_scale
	)

	bullet_name_holder.global_position = holder_position
	bullet_name_holder.size = holder_size
	bullet_name_text.position = Vector2.ZERO
	bullet_name_text.size = holder_size

func _change_current_bullet(new_bullet_type: int) -> void:
	if not refill_bullet_pattern.is_empty():
		refill_bullet_pattern[0] = new_bullet_type
	if bullets.is_empty():
		return

	var bullet_values = bullet_dictionary[new_bullet_type]
	var chambered_bullet_node = bullets[0]
	var animation_to_play = bullet_change_animation_dictionary[chambered_bullet_node.name]
	to_change_image.clear()
	_set_bullet_image(chambered_bullet_node, bullet_values.chamber_scene)
	to_change_name = bullet_values.bullet_name
	var chambered_bullet_scene = bullet_values.combat_scene
	chambered_bullet_scenes[0] = chambered_bullet_scene
	#print(animation_to_play)
	bullet_changer.play_section(animation_to_play)
	#print(chambered_bullet_names)
	name_changer.play_section("name_fade_slow")

func _change_bullet_image_during_animation(chambered_bullet_node_name: String) -> void:
	if to_change_image.is_empty():
		return

	var bullet_node = bullet_holder.find_child(chambered_bullet_node_name)
	if bullet_node:
		_set_bullet_image(bullet_node, to_change_image[0])
		to_change_image.remove_at(0)

func _change_chamber(new_bullet_type: int) -> void:
	if not refill_bullet_pattern.is_empty():
		refill_bullet_pattern.fill(new_bullet_type)
	if bullets.is_empty():
		return

	var bullet_values = bullet_dictionary[new_bullet_type]
	to_change_image.clear()
	to_change_name = bullet_values.bullet_name
	for i in bullets:
		var id = bullets.find(i)
		_set_bullet_image(i, bullet_values.chamber_scene)
		var chambered_bullet_scene = bullet_values.combat_scene
		chambered_bullet_scenes[id] = chambered_bullet_scene
		if id != 0:
			chambered_bullet_names[id-1] = bullet_values.bullet_name
	bullet_changer.play_section("chamber_change")
	name_changer.play_section("name_fade_slow")
	pass

func set_bullet() -> void:
	if to_change_name != "":
		chambered_bullet_names.push_front(to_change_name)
		to_change_name = ""

func animation_completed() -> void:
	bullet_name_changed = false


func _set_bullet_image(bullet_node: Node, texture_path: String) -> void:
	var bullet_image_node := bullet_node.get_child(0) as TextureRect
	if bullet_image_node != null:
		bullet_image_node.texture = load(texture_path)

func refill_bullets() -> void:
	if Engine.is_editor_hint():
		return
	if is_refilling:
		return

	is_refilling = true

	if anim_player.is_playing():
		anim_player.stop()
	if name_changer.is_playing():
		name_changer.stop()
	if bullet_changer.is_playing():
		bullet_changer.stop()

	for bullet_node in bullets:
		if is_instance_valid(bullet_node):
			bullet_node.queue_free()

	await get_tree().process_frame

	bullets.clear()
	for template in original_bullet_templates:
		var bullet_node := template.duplicate()
		bullet_holder.add_child(bullet_node)
		bullets.append(bullet_node)

	chambered_bullet_scenes.clear()
	chambered_bullet_names.clear()
	to_change_image.clear()
	to_change_name = ""
	bullet_name_changed = false
	cylinder_rotator.rotation_degrees = 0.0
	reset_chamber_pos()
	anim_player.play_section("RESET")
	bullet_changer.play_section("RESET")
	name_changer.play_section("RESET")
	_load_bullet_pattern()
	change_bullet_name()
	_emit_out_of_ammo_state()
	is_refilling = false

func _cache_original_bullet_templates() -> void:
	original_bullet_templates.clear()
	for bullet_node in bullets:
		if is_instance_valid(bullet_node):
			original_bullet_templates.append(bullet_node.duplicate())

func _load_bullet_pattern() -> void:
	for i in range(refill_bullet_pattern.size()):
		if i >= bullets.size():
			break

		var bullet_values = bullet_dictionary[refill_bullet_pattern[i]]
		var chambered_bullet_node = bullets[i]
		var bullet_image_node = chambered_bullet_node.get_child(0)
		bullet_image_node.texture = load(bullet_values.chamber_scene)
		chambered_bullet_names.append(bullet_values.bullet_name)
		chambered_bullet_scenes.append(bullet_values.combat_scene)

@tool
extends Control

enum BULLET_TYPE {REGULAR = 5, RUBBER = 4, PIERCING = 3, FLY = 2, SWAP = 1, SAD = 99}

const BULLET_NAME_BASE_FONT_SIZE := 14
const CHAMBER_BASE_SIZE := 64.0
const BULLET_NAME_HORIZONTAL_PADDING := 12.0
const BULLET_NAME_MIN_HEIGHT := 24.0

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
@export var cylinder_rotator: Node

@export var score_cost: int = 100
@export var bullet_name_offset: Vector2 = Vector2(0.0, -2.0)

var cylinder_start_pos
var scale_modifier := 1.0
var chamber_scale_setting := 3.0
var base_alignment_position := Vector2.ZERO
var base_alignment_scale := Vector2.ONE

@onready var bullet_name_holder: Control = $BulletNameHolder
@onready var bullet_name_text: Label = $BulletNameHolder/BulletName
@onready var cylinder_container = $alignment/VBoxContainer
@onready var alignment: Control = $alignment

func _ready() -> void:
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
	for i in range(bullet_pattern.size()):
		var bullet_values = bullet_dictionary[bullet_pattern[i]]
		var chambered_bullet_node = bullets[i]
		var bullet_image_node = chambered_bullet_node.get_child(0)
		bullet_image_node.texture = load(bullet_values.chamber_scene)
		var chambered_bullet_name = bullet_values.bullet_name
		var chambered_bullet_scene = bullet_values.combat_scene
		chambered_bullet_names.append(chambered_bullet_name)
		chambered_bullet_scenes.append(chambered_bullet_scene)
		
		if i == 5:
			break
		
	change_bullet_name()
	if not Engine.is_editor_hint():
		_emit_out_of_ammo_state()
	_refresh_bullet_name_layout()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		_refresh_bullet_name_layout()
		return

	if Input.is_action_just_pressed("shoot"):
		if chambered_bullet_scenes.size() > 0:
			BulletBus.fire_player_bullet.emit(chambered_bullet_scenes[0])
			ScoreBus.spend_score(score_cost)
			bullets[0].queue_free()
			if anim_player.is_playing():
				anim_player.stop()
				if not chambered_bullet_names.is_empty():
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
		bullet_name_text.text = chambered_bullet_names[0]
		chambered_bullet_names.remove_at(0)
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

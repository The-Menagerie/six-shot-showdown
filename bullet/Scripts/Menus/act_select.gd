extends Control

const BULLET_NAME_BASE_FONT_SIZE := 14
const CHAMBER_BASE_SIZE := 64.0
const BULLET_NAME_HORIZONTAL_PADDING := 12.0
const BULLET_NAME_MIN_HEIGHT := 24.0

@export var anim_player: Node
@export var name_changer: Node
@export var bullet_changer: Node
@export var cylinder_rotator: Node

var selected_act = 1
var act_bullet_rotation_array = [0,60,120,180,240,300]


# @onready var bullet_name_holder: Control = $BulletNameHolder
# @onready var bullet_name_text: Label = $BulletNameHolder/BulletName
@onready var cylinder_container = $alignment/VBoxContainer
@onready var alignment: Control = $alignment
@onready var bullet_holder: Control = $alignment/BulletHolder
@onready var chamber_sprite: Control = $alignment/VBoxContainer/TextureRect


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("left") and not Input.is_action_just_pressed("right"):
		move_left()
	if Input.is_action_just_pressed("right") and not Input.is_action_just_pressed("left"):
		move_right()
	#cylinder_rotator.rotation_degrees = act_bullet_rotation_array[selected_act-1]

func move_left() -> void:
	#_cut_animation_short() < This has been commented out since by calling this it will cause it to work in parallel, which causes the next animation to start too early
		selected_act += 1
		if selected_act > 6:
			selected_act -= 6
		print(selected_act)
		if anim_player.is_playing():
			#var direction = anim_player.current_animation
			anim_player.stop()
			chamber_sprite.texture.region = Rect2(0.0,0.0,128.0,128.0)
			cylinder_rotator.rotation_degrees = act_bullet_rotation_array[selected_act-1]
			#if direction == "revolve":
				#var distance_partial_rotated = fmod(cylinder_rotator.rotation_degrees,60.0)
				#rotate_chamber(60 - distance_partial_rotated)
			#if direction == "revolve_backwards":
				#var distance_partial_rotated = fmod(cylinder_rotator.rotation_degrees,60.0)
				#rotate_chamber(-60 - distance_partial_rotated)
		anim_player.play_section("revolve")

func move_right() -> void:
	#_cut_animation_short() < This has been commented out since by calling this it will cause it to work in parallel, which causes the next animation to start too early
		selected_act -= 1
		if selected_act < 1:
			selected_act += 6
		print(selected_act)
		if anim_player.is_playing():
			#var direction = anim_player.current_animation
			anim_player.stop()
			chamber_sprite.texture.region = Rect2(0.0,0.0,128.0,128.0)
			cylinder_rotator.rotation_degrees = act_bullet_rotation_array[selected_act-1]
			print(cylinder_rotator.rotation_degrees)
			#if direction == "revolve":
				#var distance_partial_rotated = fmod(cylinder_rotator.rotation_degrees,60.0)
				#rotate_chamber(60 - distance_partial_rotated)
			#if direction == "revolve_backwards":
				#var distance_partial_rotated = fmod(cylinder_rotator.rotation_degrees,60.0)
				#rotate_chamber(-60 - distance_partial_rotated)
		anim_player.play_section("revolve_backwards")

func _cut_animation_short() -> void:
	if anim_player.is_playing():
			var direction = anim_player.current_animation
			anim_player.stop()
			chamber_sprite.texture.region = Rect2(0.0,0.0,128.0,128.0)
			if direction == "revolve":
				var distance_partial_rotated = fmod(cylinder_rotator.rotation_degrees,60.0)
				rotate_chamber(60 - distance_partial_rotated)
			if direction == "revolve_backwards":
				var distance_partial_rotated = fmod(cylinder_rotator.rotation_degrees,60.0)
				rotate_chamber(-60 - distance_partial_rotated)

func rotate_chamber(rot_deg: float) -> void:
	cylinder_rotator.rotation_degrees += rot_deg
	

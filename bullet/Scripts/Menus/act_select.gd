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

var act_dictionary = {
	1: {"name": "[b]Act 1: Cave Escape[/b]",
	"description":"Head hurting you broke out of the Lack gang's restraints. Now it's high time to break the gang's hold on the caves. After that, the Town."},
	2: {"name": "[b]Act 2: Town Showdown[/b]",
	"description":"Free from the mines a chance encounter witha  veiled figure gives you the perfect tool to rid the town of the Lack's gang."},
	3: {"name": "[b]Act 3: The Ravine[/b]",
	"description":"You watch the last of the gang flee the town heading towards the distant ravines. This time revenge finds its way to the heart of the gang."}
}
var act_scenes = []

@export var act_level_paths: Array[String]


# @onready var bullet_name_holder: Control = $BulletNameHolder
# @onready var bullet_name_text: Label = $BulletNameHolder/BulletName
@onready var cylinder_container = $alignment/VBoxContainer
@onready var alignment: Control = $alignment
@onready var bullet_holder: Control = $alignment/BulletHolder
@onready var chamber_sprite: Control = $alignment/VBoxContainer/TextureRect
@onready var act_name: Control = $MarginContainer/ColorRect/MarginContainer/VBoxContainer/ActName
@onready var act_description: Control = $MarginContainer/ColorRect/MarginContainer/VBoxContainer/ActDescription


func _ready() -> void:
	for i in act_level_paths:
		var temp_scene = load(i)
		act_scenes.append(temp_scene)
	change_act_data(selected_act)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("left") and not Input.is_action_just_pressed("right"):
		move_left()
	if Input.is_action_just_pressed("right") and not Input.is_action_just_pressed("left"):
		move_right()
	if not anim_player.is_playing():
		cylinder_rotator.rotation_degrees = act_bullet_rotation_array[selected_act-1]

func move_left() -> void:
	#_cut_animation_short() < This has been commented out since by calling this it will cause it to work in parallel, which causes the next animation to start too early
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
		selected_act += 1
		if selected_act > 6:
			selected_act -= 6
		anim_player.play_section("revolve")
		change_act_data(selected_act)

func move_right() -> void:
	#_cut_animation_short() < This has been commented out since by calling this it will cause it to work in parallel, which causes the next animation to start too early
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
		selected_act -= 1
		if selected_act < 1:
			selected_act += 6
		anim_player.play_section("revolve_backwards")
		change_act_data(selected_act)

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


func _on_left_button_pressed() -> void:
	move_left()
	pass # Replace with function body.


func _on_right_button_pressed() -> void:
	move_right()
	pass # Replace with function body.

func change_act_data(act_num: int) -> void:
	if act_dictionary.has(act_num):
		var act_data = act_dictionary[act_num]
		act_name.text = act_data["name"]
		act_description.text = act_data["description"]


func _on_play_pressed() -> void:
	if act_scenes[selected_act-1]:
		ActManager.ActSelected = true
		ActManager.SelectedAct = act_scenes[selected_act-1]
	get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
	pass # Replace with function body.

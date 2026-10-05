extends Control

const BULLET_NAME_BASE_FONT_SIZE := 14
const CHAMBER_BASE_SIZE := 64.0
const BULLET_NAME_HORIZONTAL_PADDING := 12.0
const BULLET_NAME_MIN_HEIGHT := 24.0
const ACT_SCORE_SCREEN = preload("res://Scenes/UI/act_score_screen.tscn")

@export var anim_player: Node
@export var name_changer: Node
@export var bullet_changer: Node
@export var cylinder_rotator: Node

@export var skip_speed = 3.0

var selected_act = 1
var stats_screen
var act_bullet_rotation_array = [0,-60,-120,-180,-240,-300]

var act_dictionary = {
	1: {"name": "[b]Act 1: Cave Escape[/b]",
	"description":"Head hurting you broke out of the Lack gang's restraints. Now it's high time to break the gang's hold on the caves. After that, the Town."},
	2: {"name": "[b]Act 2: Town Showdown[/b]",
	"description":"Free from the mines, a chance encounter with a mysterious veiled figure gives you the perfect tool to rid the town of the Lack's gang. Can you stop them before their plan to rob the town's bank?"},
	3: {"name": "[b]Act 3: The Ravine[/b]",
	"description":"After successfully catching the Lacky Gang member's from escaping with the town's gold by train, you find yourself at the edge of the ravine and the Lacky Gang's secret saloon headquarters just out of sight. It is time to take revenge at the heart of the Lacky gang."}
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
@onready var high_score_label: Label = $MarginContainer/ColorRect/MarginContainer/VBoxContainer/HighScore
@onready var play_button: TextureButton = $MarginContainer/ColorRect/MarginContainer/VBoxContainer/Play
@onready var stats_button: TextureButton = $MarginContainer/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Stats


func _ready() -> void:
	for i in act_level_paths:
		var temp_scene = load(i)
		act_scenes.append(temp_scene)
	change_act_data(selected_act)

func _process(delta: float) -> void:
	if is_instance_valid(stats_screen):
		return
	if Input.is_action_just_pressed("left") and not Input.is_action_just_pressed("right"):
		move_left()
	if Input.is_action_just_pressed("right") and not Input.is_action_just_pressed("left"):
		move_right()
	if not anim_player.is_playing():
		cylinder_rotator.rotation_degrees = act_bullet_rotation_array[selected_act-1]

func move_left() -> void:
	if is_instance_valid(stats_screen):
		return
	if anim_player.is_playing():
		anim_player.stop()
		chamber_sprite.texture.region = Rect2(0.0, 0.0, 128.0, 128.0)
		cylinder_rotator.rotation_degrees = act_bullet_rotation_array[selected_act - 1]
	selected_act -= 1
	if selected_act < 1:
		selected_act += 6
	anim_player.speed_scale = 1.0 if act_dictionary.has(selected_act) else skip_speed
	anim_player.play_section("revolve")
	change_act_data(selected_act)

func move_right() -> void:
	if is_instance_valid(stats_screen):
		return
	if anim_player.is_playing():
		anim_player.stop()
		chamber_sprite.texture.region = Rect2(0.0, 0.0, 128.0, 128.0)
		cylinder_rotator.rotation_degrees = act_bullet_rotation_array[selected_act - 1]
	selected_act += 1
	if selected_act > 6:
		selected_act -= 6
	anim_player.speed_scale = 1.0 if act_dictionary.has(selected_act) else skip_speed
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
	high_score_label.visible = act_dictionary.has(act_num)
	var stats := ActManager.get_act_stats(act_num)
	high_score_label.text = "High Score: %d" % int(stats["high_score"]) if stats.has("high_score") else "High Score: Unplayed"
	stats_button.disabled = not act_dictionary.has(act_num)
	play_button.disabled = not act_dictionary.has(act_num) or not ActManager.is_act_unlocked(act_num)
	play_button.modulate = Color(1.0, 1.0, 1.0, 0.4) if play_button.disabled else Color.WHITE
	if act_dictionary.has(act_num):
		var act_data = act_dictionary[act_num]
		act_name.text = act_data["name"]
		if ActManager.is_act_unlocked(act_num):
			act_description.text = act_data["description"]
		else:
			act_name.text += " [b](Locked)[/b]"
			act_description.text = "Beat Act %d to unlock this act." % (act_num - 1)


func _on_play_pressed() -> void:
	if is_instance_valid(stats_screen):
		return
	if not act_dictionary.has(selected_act) or not ActManager.is_act_unlocked(selected_act):
		return
	if selected_act > act_scenes.size() or act_scenes[selected_act-1] == null:
		return
	ActManager.ActSelected = true
	ActManager.SelectedAct = act_scenes[selected_act-1]
	MusicManager.stop_music()
	get_tree().change_scene_to_file("res://Scenes/main_game.tscn")

func _on_stats_pressed() -> void:
	if not act_dictionary.has(selected_act) or is_instance_valid(stats_screen):
		return
	stats_screen = ACT_SCORE_SCREEN.instantiate()
	stats_screen.selected_act = selected_act
	stats_screen.back_requested.connect(_on_stats_closed)
	add_child(stats_screen)

func _on_stats_closed() -> void:
	if is_instance_valid(stats_screen):
		stats_screen.queue_free()
	stats_screen = null
	stats_button.grab_focus()

func validate_data(dir: String) -> void:
	if not act_dictionary.has(selected_act):
		if dir == "left":
			move_left()
		elif dir == "right":
			move_right()
	else:
		anim_player.speed_scale = 1.0

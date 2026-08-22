extends Control

@onready var animation_player: AnimationPlayer = $ScreenAdjuster/AnimationPlayer
@onready var continue_button: Button = $ScreenAdjuster/Button
@onready var reveal_masks: Control = $ScreenAdjuster/RevealMasks
@onready var cutscene: Node2D = $ScreenAdjuster/Sprite2D

var last_known_size_y = 1080
var last_known_size_x = 1920
var to_adjust: Array[Node]

func _ready() -> void:
	
	to_adjust.append(continue_button)
	to_adjust.append(cutscene)
	for child in reveal_masks.get_children():
		to_adjust.append(child)
	
	adjust()
	
	if is_instance_valid(animation_player) and animation_player.has_animation("Cutscene"):
		animation_player.play("Cutscene")

	for child in reveal_masks.get_children():
		if child.has_method("start_reveal"):
			child.start_reveal()

	if is_instance_valid(continue_button) and not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)

func _on_continue_pressed() -> void:
	MusicManager.stop_music()
	get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
	

func _process(delta: float) -> void:
	
	adjust()


func adjust() -> void:
	var adjustment_distance_x
	var adjustment_distance_y
	
	if self.size.x != last_known_size_x:
		last_known_size_x = self.size.x
		#print(last_known_size_x)
		adjustment_distance_x = (self.size.x - last_known_size_x)/2
	
	
	if self.size.y != last_known_size_y:
		last_known_size_y = self.size.y
		print(last_known_size_y)
		adjustment_distance_y = (self.size.y - last_known_size_y)/2
	if self.size.x != last_known_size_x or self.size.y != last_known_size_y:
		for i in to_adjust:
			i.position.x += adjustment_distance_x
			i.position.y += adjustment_distance_y

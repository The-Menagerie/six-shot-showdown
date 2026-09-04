extends "res://Scripts/Bullets/bullet.gd"

# TO ADD
# MELTS ICE BLOCKS
# SLOW BURN ROPES

var fire_droplet_scene := preload("res://Scenes/Objects/FireDroplet.tscn")
var droplet_scenes: Array[PackedScene]

func _after_ready() -> void:
	for i in range(max_bounces):
		droplet_scenes.append(fire_droplet_scene)

func _before_move(_segment_start: Vector2, _segment_end: Vector2) -> void:
	pass

func _on_confirmed_bounce(collision: KinematicCollision2D) -> void:
	if not droplet_scenes.is_empty():
		var soon_to_drop = droplet_scenes[0].instantiate()
		var world_parent := get_parent()
		if world_parent != null:
			world_parent.add_child(soon_to_drop)
			soon_to_drop.global_position = global_position
	super._on_confirmed_bounce(collision)

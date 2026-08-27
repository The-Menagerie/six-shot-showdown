extends RigidBody2D

@export var anim_player: Node

@export var falling_velocity := 3
var velocity:= Vector2(0,0)

var flame_field_path = preload("res://Scenes/Objects/FlameField.tscn")
var flame_field_scene  

func _ready() -> void:
	velocity.y = falling_velocity
	anim_player.play_section("falling")
	
func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity)
	if collision:
		var collider = collision.get_collider()
		var collision_pos = collision.get_position()
		if collider is TileMapLayer:
			var collision_cell_pos = collider.local_to_map(collision_pos)
			print(collision_cell_pos)
			var direct_above_pos = Vector2i(collision_cell_pos.x,collision_cell_pos.y-1)
			print(direct_above_pos)
			if collider.get_cell_source_id(direct_above_pos) == -1:
				var new_pos = collider.map_to_local(direct_above_pos)
				flame_field_scene = flame_field_path.instantiate()
				var world_parent := get_parent()
				if world_parent != null:
					world_parent.add_child(flame_field_scene)
					flame_field_scene.global_position = new_pos
						
		queue_free()
	
	
func _on_area_entered(body: Node) -> void:
	if body is TileMapLayer:
		print("fire hit tile")
	pass

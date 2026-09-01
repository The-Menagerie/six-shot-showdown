extends "res://Scripts/Bullets/bullet.gd"

# TO ADD
# FREEZE LAVA
# ICE CUBES MELT WITH FIRE BULLETS

var ice_cube_scene_path := preload("res://Scenes/Objects/IceCube.tscn")
var ice_cube_scene

func _after_ready() -> void:
	ice_cube_scene = ice_cube_scene_path.instantiate()

func _before_move(_segment_start: Vector2, _segment_end: Vector2) -> void:
	pass

func _try_damage_hitbox(area: Area2D) -> bool:
	if not area.is_in_group("hitbox"):
		return false

	var parent = area.get_parent()
	freeze_em(parent)
	return true

func freeze_em(entity: Node) -> void:
	var world_parent = get_parent()
	if world_parent:
		world_parent.add_child(ice_cube_scene)
		var entity_sprite = entity.find_children("*", "Sprite2D")[0]
		ice_cube_scene.global_position = entity.global_position
		ice_cube_scene.frozen_texture.texture = entity_sprite.texture
		ice_cube_scene.frozen_texture.hframes = entity_sprite.hframes
		ice_cube_scene.frozen_texture.vframes = entity_sprite.vframes
		ice_cube_scene.frozen_texture.frame = entity_sprite.frame
		var h_dimensions = entity_sprite.texture.get_width() / entity_sprite.hframes
		var v_dimensions = entity_sprite.texture.get_height() / entity_sprite.vframes

		if h_dimensions > 32.0:
			ice_cube_scene.scale.x = h_dimensions / 32.0
		if v_dimensions > 32.0:
			ice_cube_scene.scale.y = v_dimensions / 32.0
	entity.target_destroyed.emit(entity)
	entity.queue_free()

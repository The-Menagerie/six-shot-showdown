extends CharacterBody2D

@export var speed : float = 500.0
@export var damage : float = 10.0
@export var max_bounces : int = 3
@export var recoil_multiplier: float = 1.0
@export var rope_pass_through_distance : float = 6.0

var direction : Vector2 = Vector2.RIGHT
var area_2d: Area2D
var bounce_count : int = 0
var shooter: Node

var ice_cube_scene_path = preload("res://Scenes/Objects/IceCube.tscn")
var ice_cube_scene

@onready var ricochet_audio: AudioStreamPlayer = $RicochetAudio

func _ready():
	area_2d = $Area2D
	area_2d.area_entered.connect(_on_area_entered)
	area_2d.add_to_group("bullet")
	ice_cube_scene = ice_cube_scene_path.instantiate()

func _physics_process(delta):
	velocity = direction * speed
	var next_position: Vector2 = global_position + velocity * delta
	if _try_cut_rope_between(global_position, next_position):
		global_position = next_position
		rotation = direction.angle()
		return

	var collision = move_and_collide(velocity * delta)
	if collision:
		if _try_damage_collider(collision.get_collider()):
			queue_free()
			return
		if bounce_count >= max_bounces:
			ricochet_audio.play()
			queue_free()
			return
		if not _confirm_bounce(collision):
			queue_free()
			return
		bounce_count += 1
		direction = direction.bounce(collision.get_normal()).normalized()
		rotation = direction.angle()
		ricochet_audio.play()


func _on_area_entered(area: Area2D):
	if _try_damage_hitbox(area):
		queue_free()

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
	rotation = direction.angle()
	#print("Bullet velocity set to: "+str(direction))

func _try_damage_collider(collider: Node) -> bool:
	if collider is Area2D:
		return _try_damage_hitbox(collider)

	if collider.has_method("apply_bullet_knockback"):
		collider.apply_bullet_knockback(direction)

	for child in collider.get_children():
		if child is Area2D and _try_damage_hitbox(child):
			return true

	return false

func _try_damage_hitbox(area: Area2D) -> bool:
	if not area.is_in_group("hitbox"):
		return false
	
	var parent = area.get_parent()
	freeze_em(parent)
	#var attack = Attack.new()
	#attack.attack_damage = damage
	#area.damage(attack)
	#parent.queue_free()
	return true

func freeze_em(entity:Node) -> void:
	var world_parent = get_parent()
	if world_parent:
		world_parent.add_child(ice_cube_scene)
		var entity_sprite = entity.find_children("*","Sprite2D")[0]
		ice_cube_scene.global_position = entity.global_position
		ice_cube_scene.frozen_texture.texture = entity_sprite.texture
		ice_cube_scene.frozen_texture.hframes = entity_sprite.hframes
		ice_cube_scene.frozen_texture.vframes = entity_sprite.vframes
		ice_cube_scene.frozen_texture.frame = entity_sprite.frame
		var h_dimensions = entity_sprite.texture.get_width()/entity_sprite.hframes
		var v_dimensions = entity_sprite.texture.get_height()/entity_sprite.vframes
		
		if h_dimensions > 32.0:
			ice_cube_scene.scale.x = h_dimensions/32.0
		if v_dimensions > 32.0:
			ice_cube_scene.scale.y = v_dimensions/32.0
	entity.target_destroyed.emit(entity)
	entity.queue_free()
	pass
func _confirm_bounce(collision: KinematicCollision2D) -> bool:
	var collider = collision.get_collider()
	var collision_pos = collision.get_position()
	if collider is TileMapLayer:
		var collision_cell_pos = collider.local_to_map(collision_pos)
		var data = collider.get_cell_tile_data(collision_cell_pos)
		if data == null:
			var near_cells = collider.get_surrounding_cells(collision_cell_pos)
			var nearby_bounce_count = 0
			for i in near_cells:
				data = collider.get_cell_tile_data(i)
				if data != null:
					if data.get_custom_data("bullets_bounce"):
						nearby_bounce_count += 1
					else:
						nearby_bounce_count -= 1
			if nearby_bounce_count < 0:
				#print(nearby_bounce_count)
				return false
			else:
				#print(nearby_bounce_count)
				return true
		if data != null:
			if not data.get_custom_data("bullets_bounce"):
				return false
	return true

func _try_cut_rope_between(segment_start: Vector2, segment_end: Vector2) -> bool:
	var ropes: Array[Node] = get_tree().get_nodes_in_group("rope")
	for rope: Node in ropes:
		if rope.has_method("cut_along_segment") and rope.cut_along_segment(segment_start, segment_end, rope_pass_through_distance):
			return true

	return false

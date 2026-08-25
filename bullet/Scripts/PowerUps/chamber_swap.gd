extends PickUp

enum BULLET_TYPE {REGULAR = 5, RUBBER = 4, PIERCING = 3, FLY = 2, SWAP = 1, SAD = 99}

@export var chamber_swap_target: BULLET_TYPE

var bullet_color_dict = {
	5: Vector4(0.68, 0.68, 0.0, 0.0),
	4: Vector4(0.188, 0.616, 0.314,0.0),
	3: Vector4(0.73, 0.442, 0.195,0.0),
	2: Vector4(0.294, 0.553, 0.714,0.0),
	1: Vector4(0.69, 0.306, 0.906,0.0),
	99: Vector4(0.117, 0.171, 0.766,0.0),
}

func additional_ready_steps() -> void:
	self.get_material().set_shader_parameter("outline_color", bullet_color_dict[chamber_swap_target])
	
func collected(body:Node2D) -> void:
	BulletBus.chamber_swap.emit(chamber_swap_target)

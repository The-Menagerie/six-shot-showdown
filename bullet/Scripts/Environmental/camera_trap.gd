extends Area2D

@export var cam_node: Node

var camera_caught:= false
var tree_root

func _ready() -> void:
	tree_root = get_tree().get_root()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("yo")
		if camera_caught == false:
			cam_node.reparent(tree_root)
			camera_caught = true
		elif camera_caught == true:
			cam_node.reparent(body)




func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if camera_caught == true:
			if body.global_position.y > self.global_position.y:
				cam_node.reparent(body)
				camera_caught = false
				if not cam_node.position.y == 0:
					var tween = get_tree().create_tween()
					tween.tween_property(cam_node,"position",Vector2(),0.33)
				
	pass # Replace with function body.

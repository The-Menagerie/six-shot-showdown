extends breakable

var carried_drops: Array[Node2D] = []

func _after_ready() -> void:
	carried_drops = _find_carried_drops()
	for carried_drop in carried_drops:
		if is_instance_valid(carried_drop) and carried_drop.has_method("set_carried_state"):
			carried_drop.set_carried_state(true)

func _find_carried_drops() -> Array[Node2D]:
	var drops: Array[Node2D] = []
	for child in find_children("*", "Node2D", true, false):
		if child == self:
			continue
		if child.has_method("set_carried_state") and child.has_method("drop_from_carrier"):
			drops.append(child)

	return drops
	
func _finish_drop_carried_item(drop_node: Node2D, parent: Node, drop_global_position: Vector2) -> void:
	if not is_instance_valid(drop_node):
		return
	if parent == null or not is_instance_valid(parent):
		return

	var drop_parent := drop_node.get_parent()
	if drop_parent != null:
		drop_parent.remove_child(drop_node)
	parent.add_child(drop_node)
	drop_node.global_position = drop_global_position

	if drop_node.has_method("drop_from_carrier"):
		drop_node.drop_from_carrier()

func _other_death_effects():
	_drop_carried_items()

func _drop_carried_items() -> void:
	var parent = get_parent()
	if parent == null:
		return

	for carried_drop in carried_drops:
		if not is_instance_valid(carried_drop):
			continue

		var drop_node: Node2D = carried_drop
		var drop_global_position: Vector2 = carried_drop.global_position
		call_deferred("_finish_drop_carried_item", drop_node, parent, drop_global_position)

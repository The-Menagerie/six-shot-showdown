extends OptionButton




func _on_item_selected(index: int) -> void:
	BulletBus.change_chamber_scale(float(index)+1.0)
	pass # Replace with function body.

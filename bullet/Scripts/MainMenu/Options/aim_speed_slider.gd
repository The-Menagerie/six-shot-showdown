extends HSlider

var aim_speed_label: Control

func _ready() -> void:
	min_value = SettingsManager.MIN_AIM_SPEED
	max_value = SettingsManager.MAX_AIM_SPEED
	step = 10.0
	value = SettingsManager.aim_speed
	value_changed.connect(_on_value_changed)
	aim_speed_label = _get_label_above_slider()
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_update_visibility()

func _on_value_changed(new_value: float) -> void:
	SettingsManager.set_aim_speed(new_value)

func _exit_tree() -> void:
	if Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.disconnect(_on_joy_connection_changed)

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_update_visibility()

func _update_visibility() -> void:
	var should_show := Input.get_connected_joypads().size() > 0
	visible = should_show
	if aim_speed_label != null:
		aim_speed_label.visible = should_show

func _get_label_above_slider() -> Control:
	var parent_node := get_parent()
	if parent_node == null:
		return null

	var siblings := parent_node.get_children()
	var slider_index := siblings.find(self)
	if slider_index <= 0:
		return null

	return siblings[slider_index - 1] as Control

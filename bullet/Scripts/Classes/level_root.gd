class_name LevelRoot extends Node2D

@export var targets: Array[Node] = []
@export var next_level_path: String
@export_range(0.0, 5.0, 0.1) var next_level_delay: float = 0.4
var next_level
var num_targets
var game_manager
var has_targets = false
var targets_left
var is_level_transition_queued := false


func _ready() -> void:
	next_level = load(next_level_path)
	game_manager = get_parent()
	# Removed or duplicated editor entries must not block level completion.
	var valid_targets: Array[Node] = []
	for target in targets:
		if is_instance_valid(target) and target.has_signal("target_destroyed") and not valid_targets.has(target):
			valid_targets.append(target)
	targets = valid_targets
	num_targets = self.targets.size()
	if num_targets > 0:
		has_targets = true
		targets_left = num_targets
		
		for t in targets:
			if t != null:
				t.target_destroyed.connect(target_down)


func target_down(target:Node) -> void:
	if is_level_transition_queued:
		return

	var target_index = targets.find(target)
	if target_index < 0:
		return
	targets.remove_at(target_index)
	targets_left = targets.size()
	if targets_left <= 0:
		send_to_next_level()
		#is_level_transition_queued = true
		#if game_manager != null and game_manager.has_method("transition_to_level"):
			#game_manager.transition_to_level(next_level, next_level_delay)
			#return
		#if next_level_delay > 0.0:
			#await get_tree().create_timer(next_level_delay).timeout
		#game_manager.change_level(next_level)
		
func send_to_next_level() -> void:
	if is_level_transition_queued:
		return
	is_level_transition_queued = true
	if game_manager != null and game_manager.has_method("transition_to_level"):
		game_manager.transition_to_level(next_level, next_level_delay)
		return
	if next_level_delay > 0.0:
		await get_tree().create_timer(next_level_delay).timeout
	game_manager.change_level(next_level)

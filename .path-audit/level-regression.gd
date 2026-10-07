extends SceneTree

class TestManager extends Node2D:
	var transitions := 0
	var destination: PackedScene
	func transition_to_level(scene: PackedScene, _delay: float) -> void:
		transitions += 1
		destination = scene
	func reset_current_level() -> void:
		pass

class TestTarget extends Node:
	signal target_destroyed(target: Node)

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var manager := TestManager.new()
	manager.name = "MainGame"
	root.add_child(manager)
	current_scene = manager
	for act in ([] if "--mechanics-only" in OS.get_cmdline_user_args() else range(1, 4)):
		for number in range(1, 13):
			if act == 2 and number == 7:
				continue # This level is intentionally absent from the existing chain.
			var path := "res://Scenes/Levels/Act %d/act%d_lvl%d.tscn" % [act, act, number]
			var packed := load(path) as PackedScene
			_check(packed != null, "Cannot load " + path)
			if packed == null:
				continue
			var level := packed.instantiate() as LevelRoot
			_check(level != null, "Cannot instantiate " + path)
			if level == null:
				continue
			manager.transitions = 0
			manager.add_child(level)
			_check(level.next_level != null, "Missing next level for " + path)
			_check(level.targets_left == level.targets.size(), "Invalid target count for " + path)
			for frame in range(60):
				await physics_frame
				await process_frame
			# Isolate completion accounting from any deaths during the simulation.
			manager.transitions = 0
			level.is_level_transition_queued = false
			var remaining := level.targets.duplicate()
			for target in remaining:
				target.target_destroyed.emit(target)
			_check(manager.transitions == 1, "Completion did not transition exactly once: " + path)
			level.send_to_next_level()
			_check(manager.transitions == 1, "Repeated completion queued another transition: " + path)
			_check(manager.destination != null and manager.destination.resource_path == level.next_level_path, "Wrong destination: " + path)
			print("LEVEL_PASS|", path)
			var chamber = level.get_node("CanvasLayer/Chamber")
			var template_ids: Array[int] = []
			for template in chamber.original_bullet_templates:
				template_ids.append(template.get_instance_id())
			level.queue_free()
			await process_frame
			await process_frame
			for template_id in template_ids:
				_check(not is_instance_id_valid(template_id), "Chamber template leaked after exiting " + path)

	# Simulate stale and duplicate target entries left by a scene merge.
	var level := LevelRoot.new()
	level.next_level_path = "res://Scenes/Levels/Act 3/act3_lvl11.tscn"
	var target := TestTarget.new()
	level.add_child(target)
	level.targets.assign([null, target, target])
	manager.transitions = 0
	manager.add_child(level)
	_check(level.targets_left == 1, "Stale or duplicate targets counted toward completion")
	target.target_destroyed.emit(target)
	target.target_destroyed.emit(target)
	_check(manager.transitions == 1, "Repeated target signal queued multiple transitions")
	level.queue_free()
	await process_frame

	var boulder = load("res://Scenes/Objects/Boulder.tscn").instantiate()
	manager.add_child(boulder)
	boulder.freeze = true
	_check(boulder.get_node("HitboxComponent").is_in_group("hitbox"), "Boulder has no functioning swap hitbox")
	boulder.angular_velocity = 0.0
	boulder.last_frame_ang_speed = 0.0
	boulder._physics_process(1.0 / 60.0)
	_check(is_finite(boulder.angular_velocity) and boulder.angular_velocity == 0.0, "Stationary boulder rotation became invalid")
	for frame in range(5):
		boulder.angular_velocity = 100.0
		boulder._physics_process(1.0 / 60.0)
	_check(is_equal_approx(boulder.angular_velocity, 45.0), "Boulder rotation failed to accumulate across frames")
	boulder.stabilize_after_swap(Vector2(2000, -2000))
	for frame in range(4):
		await physics_frame
		await process_frame
	_check(boulder.angular_velocity == 0.0 and boulder.last_frame_ang_speed == 0.0, "Swap retained boulder rotation")
	_check(not boulder.freeze, "Swap left boulder frozen")
	var player = load("res://Scenes/Objects/Player/player.tscn").instantiate()
	manager.add_child(player)
	player.global_position = Vector2(2300, -2000)
	player.set_physics_process(false)
	var swap = load("res://Scenes/Objects/Bullets/swap_bullet.tscn").instantiate()
	swap.shooter = player
	manager.add_child(swap)
	swap.set_physics_process(false)
	var player_origin: Vector2 = player.global_position
	var boulder_origin: Vector2 = boulder.global_position
	_check(swap._try_damage_hitbox(boulder.get_node("HitboxComponent")), "Swap bullet did not recognize boulder")
	_check(player.global_position.distance_to(player_origin) > 100.0, "Swap did not move player")
	_check(boulder.global_position.distance_to(boulder_origin) > 100.0, "Swap did not move boulder")
	for frame in range(4):
		await physics_frame
		await process_frame
	_check(not boulder.freeze and is_zero_approx(boulder.angular_velocity), "Bullet swap left boulder frozen or spinning")
	swap.queue_free()
	player.queue_free()
	boulder.queue_free()
	await process_frame
	manager.queue_free()
	await process_frame
	print("REGRESSION_RESULT|", failures, " failures")
	quit(0 if failures == 0 else 1)

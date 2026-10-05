extends Node

const PROGRESS_PATH := "user://act_progress.cfg"
const ACT_COMPLETION_TRANSITIONS := {
	1: ["res://Scenes/Levels/Act 1/act1_lvl12.tscn", "res://Scenes/Levels/Act 2/act2_lvl1.tscn"],
	2: ["res://Scenes/Levels/Act 2/act2_lvl12.tscn", "res://Scenes/Levels/Act 3/act3_lvl1.tscn"],
	3: ["res://Scenes/Levels/Act 3/act3_lvl12.tscn", "res://Scenes/UI/temp_score_scene.tscn"]
}

var ActSelected = false

var SelectedAct
var active_profile: int = 1
var _profiles: Dictionary = {}
var completed_acts: int = 0
var act_stats: Dictionary = {}
var _active_act := 0

func _ready() -> void:
	var progress := ConfigFile.new()
	_profiles = {}
	active_profile = 1
	if progress.load(PROGRESS_PATH) == OK:
		if progress.has_section("profiles"):
			var saved_slot: Variant = progress.get_value("profiles", "active_profile", 1)
			if saved_slot is int:
				active_profile = clampi(saved_slot, 1, 3)
			for slot in range(1, 4):
				var data: Variant = progress.get_value("profile_%d" % slot, "data", {})
				if data is Dictionary:
					_profiles[slot] = data.duplicate(true)
		else:
			# Preserve the original single save as Profile 1.
			_profiles[1] = {
				"completed_acts": progress.get_value("progress", "completed_acts", 0),
				"act_stats": progress.get_value("progress", "act_stats", {})
			}
	_load_profile()

func _load_profile() -> void:
	var data: Dictionary = _profiles.get(active_profile, {})
	var saved_completed: Variant = data.get("completed_acts", 0)
	completed_acts = clampi(saved_completed, 0, 2) if saved_completed is int else 0
	var saved_stats: Variant = data.get("act_stats", {})
	act_stats = saved_stats.duplicate(true) if saved_stats is Dictionary else {}

func is_act_unlocked(act_number: int) -> bool:
	return act_number >= 1 and act_number <= 3 and act_number <= completed_acts + 1

func get_completed_act_for_transition(level_path: String, next_level_path: String) -> int:
	for act_number: int in ACT_COMPLETION_TRANSITIONS:
		var transition: Array = ACT_COMPLETION_TRANSITIONS[act_number]
		if level_path == transition[0] and next_level_path == transition[1]:
			return act_number
	return 0

func record_level_completion(level_path: String, next_level_path: String) -> void:
	for act_number: int in ACT_COMPLETION_TRANSITIONS:
		var transition: Array = ACT_COMPLETION_TRANSITIONS[act_number]
		if level_path != transition[0] or next_level_path != transition[1]:
			continue
		var progress_changed := false
		if act_number == completed_acts + 1 and act_number <= 2:
			completed_acts = act_number
			progress_changed = true
		if _active_act == act_number:
			ScoreBus.finish_run()
			_record_act_stats(act_number)
			end_act_attempt()
			progress_changed = true
		if progress_changed:
			_save_progress()
		return

func begin_level(level_path: String) -> void:
	for act_number: int in ACT_COMPLETION_TRANSITIONS:
		var first_level_path := "res://Scenes/Levels/Act %d/act%d_lvl1.tscn" % [act_number, act_number]
		if level_path != first_level_path or _active_act == act_number:
			continue
		_active_act = act_number
		ScoreBus.start_run()
		return

func end_act_attempt() -> void:
	_active_act = 0
	ScoreBus.finish_run()

func _record_act_stats(act_number: int) -> void:
	var previous: Dictionary = get_act_stats(act_number)
	var elapsed_msec := ScoreBus.get_elapsed_run_time_msec()
	var shots := ScoreBus.shots_taken
	var resets := ScoreBus.reset_count
	var deaths := ScoreBus.death_count
	var act_score := ScoreBus.current_score
	var runs := get_act_leaderboard(act_number)
	runs.append({"reputation": act_score, "shots": shots, "resets": resets, "deaths": deaths, "time_msec": elapsed_msec})
	act_stats[act_number] = {
		"completions": int(previous.get("completions", 0)) + 1,
		"last_score": act_score,
		"high_score": maxi(int(previous.get("high_score", act_score)), act_score),
		"best_time_msec": mini(int(previous.get("best_time_msec", elapsed_msec)), elapsed_msec),
		"last_time_msec": elapsed_msec,
		"shots": shots,
		"resets": resets,
		"deaths": deaths,
		"runs": runs
	}

func get_act_stats(act_number: int) -> Dictionary:
	var stats: Variant = act_stats.get(act_number, {})
	return stats.duplicate() if stats is Dictionary else {}

func get_act_leaderboard(act_number: int) -> Array[Dictionary]:
	var stats := get_act_stats(act_number)
	var results: Array[Dictionary] = []
	var saved_runs: Variant = stats.get("runs", [])
	if saved_runs is Array:
		for run: Variant in saved_runs:
			if not run is Dictionary:
				continue
			var valid := true
			for key in ["reputation", "shots", "resets", "deaths", "time_msec"]:
				if not run.get(key) is int:
					valid = false
			if valid:
				results.append(run.duplicate())
	# Older saves retained only their latest completed run.
	if not stats.has("runs") and stats.has("last_score"):
		results.append({
			"reputation": int(stats["last_score"]),
			"shots": int(stats.get("shots", 0)), "resets": int(stats.get("resets", 0)),
			"deaths": int(stats.get("deaths", 0)), "time_msec": int(stats.get("last_time_msec", 0))
		})
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["reputation"] == b["reputation"]:
			return a["time_msec"] < b["time_msec"]
		return a["reputation"] > b["reputation"]
	)
	return results

func has_completed_game() -> bool:
	return not get_act_leaderboard(3).is_empty()

func get_final_score_summary(use_recent: bool = false) -> Dictionary:
	var summary := {"acts": [], "reputation": 0, "shots": 0, "resets": 0, "deaths": 0, "time_msec": 0}
	for act_number in range(1, 4):
		var selected_run: Dictionary = {}
		if use_recent:
			# These fields are saved together on every completion, even a worse replay.
			var stats := get_act_stats(act_number)
			if stats.has("last_score"):
				selected_run = {
					"reputation": stats["last_score"], "shots": stats.get("shots", 0),
					"resets": stats.get("resets", 0), "deaths": stats.get("deaths", 0),
					"time_msec": stats.get("last_time_msec", 0)
				}
		else:
			# The leaderboard ranks reputation first, then the fastest matching run.
			var runs := get_act_leaderboard(act_number)
			selected_run = runs[0] if not runs.is_empty() else {}
		var act_result := {"act": act_number, "completed": not selected_run.is_empty()}
		for key in ["reputation", "shots", "resets", "deaths", "time_msec"]:
			act_result[key] = int(selected_run.get(key, 0))
			summary[key] += act_result[key]
		summary["acts"].append(act_result)
	return summary

func get_profile_data(slot: int) -> Dictionary:
	if slot < 1 or slot > 3:
		return {}
	if slot == active_profile:
		return {"completed_acts": completed_acts, "act_stats": act_stats.duplicate(true)}
	return _profiles.get(slot, {}).duplicate(true)

func select_profile(slot: int) -> Error:
	if slot < 1 or slot > 3:
		return ERR_INVALID_PARAMETER
	if slot == active_profile:
		return OK
	var previous_profiles := _profiles.duplicate(true)
	var previous_slot := active_profile
	var previous_completed := completed_acts
	var previous_stats := act_stats
	_profiles[active_profile] = get_profile_data(active_profile)
	active_profile = slot
	_load_profile()
	var error := _save_progress()
	if error != OK:
		_profiles = previous_profiles
		active_profile = previous_slot
		completed_acts = previous_completed
		act_stats = previous_stats
	else:
		_clear_attempt()
	return error

func delete_profile(slot: int) -> Error:
	if slot < 1 or slot > 3:
		return ERR_INVALID_PARAMETER
	var previous_profiles := _profiles.duplicate(true)
	var previous_completed := completed_acts
	var previous_stats := act_stats
	_profiles.erase(slot)
	if slot == active_profile:
		completed_acts = 0
		act_stats = {}
	var error := _save_progress()
	if error != OK:
		_profiles = previous_profiles
		completed_acts = previous_completed
		act_stats = previous_stats
	elif slot == active_profile:
		_clear_attempt()
	return error

func _clear_attempt() -> void:
	ActSelected = false
	SelectedAct = null
	end_act_attempt()
	ScoreBus.reset_run_stats()

func _save_progress() -> Error:
	_profiles[active_profile] = get_profile_data(active_profile)
	var progress := ConfigFile.new()
	progress.set_value("profiles", "active_profile", active_profile)
	for slot: int in _profiles:
		progress.set_value("profile_%d" % slot, "data", _profiles[slot])
	var error := progress.save(PROGRESS_PATH)
	if error != OK:
		push_warning("Could not save act progress: %s" % error_string(error))
	return error

extends Node

signal score_update(score_change) ##Positive score change value
signal score_changed(score: int)
signal score_loss_indicator(amount)

var starting_score: int = 77777
var score_per_shot: int = -250
var score_on_enemy_bullet_hit: int = -50
var score_on_spike_death: int = -500
var score_on_crush_death: int = -500
var score_on_burn: int = -20
var burn_time: int = 0
var passive_score_loss_per_second: int = 1
var shots_taken: int = 0
var reset_count: int = 0
var death_count: int = 0
var current_score: int = 0

var _passive_score_timer: float = 0.0
var _last_passive_score_tick_msec: int = 0
var _run_start_msec: int = 0
var _run_active := false
var _elapsed_run_msec: int = 0
var _pause_started_msec: int = -1

func _ready() -> void:
	_last_passive_score_tick_msec = Time.get_ticks_msec()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_pause_started_msec = Time.get_ticks_msec()
	elif what == NOTIFICATION_UNPAUSED and _pause_started_msec >= 0:
		if _run_active:
			var paused_msec := Time.get_ticks_msec() - _pause_started_msec
			# Keep real-time scoring, but exclude time spent in the pause menu.
			_run_start_msec += paused_msec
			_last_passive_score_tick_msec += paused_msec
		_pause_started_msec = -1

func _process(_delta: float) -> void:
	if get_tree().paused:
		return
	if not _run_active or passive_score_loss_per_second <= 0:
		_last_passive_score_tick_msec = Time.get_ticks_msec()
		return

	var now_msec := Time.get_ticks_msec()
	if _last_passive_score_tick_msec == 0:
		_last_passive_score_tick_msec = now_msec
		return

	_passive_score_timer += float(now_msec - _last_passive_score_tick_msec) / 1000.0
	_last_passive_score_tick_msec = now_msec

	while _passive_score_timer >= 1.0:
		_passive_score_timer -= 1.0
		apply_score_change(-passive_score_loss_per_second, false)

func reset_score() -> void:
	current_score = starting_score
	score_changed.emit(current_score)

func player_fired_shot() -> void:
	if not _run_active:
		return
	shots_taken += 1
	apply_score_change(score_per_shot)

func player_hit_by_enemy_bullet() -> void:
	apply_score_change(score_on_enemy_bullet_hit)

func register_player_death() -> void:
	if not _run_active:
		return
	death_count += 1

func player_died_to_spikes() -> void:
	register_player_death()
	apply_score_change(score_on_spike_death)

func player_died_to_crush() -> void:
	register_player_death()
	apply_score_change(score_on_crush_death)

func player_burning() -> void:
	if not _run_active:
		return
	burn_time += 1
	if burn_time >= abs(score_on_burn):
		apply_score_change(score_on_burn)
		burn_time = 0

func spend_score(amount: int) -> void:
	apply_score_change(-abs(amount))

func start_run() -> void:
	shots_taken = 0
	reset_count = 0
	death_count = 0
	burn_time = 0
	_elapsed_run_msec = 0
	_run_active = true
	_run_start_msec = Time.get_ticks_msec()
	_pause_started_msec = _run_start_msec if get_tree().paused else -1
	_passive_score_timer = 0.0
	_last_passive_score_tick_msec = _run_start_msec
	reset_score()

func finish_run() -> void:
	if _run_active:
		_elapsed_run_msec = get_elapsed_run_time_msec()
	_run_active = false
	_passive_score_timer = 0.0
	_last_passive_score_tick_msec = Time.get_ticks_msec()

func reset_run_stats() -> void:
	shots_taken = 0
	reset_count = 0
	death_count = 0
	burn_time = 0
	current_score = 0
	_elapsed_run_msec = 0
	_run_start_msec = 0
	_run_active = false
	_passive_score_timer = 0.0
	_last_passive_score_tick_msec = Time.get_ticks_msec()
	score_changed.emit(current_score)

func is_run_active() -> bool:
	return _run_active

func register_level_reset() -> void:
	if not _run_active:
		return
	reset_count += 1

func get_elapsed_run_time_msec() -> int:
	if not _run_active:
		return _elapsed_run_msec
	var now_msec := _pause_started_msec if _pause_started_msec >= 0 else Time.get_ticks_msec()
	return max(now_msec - _run_start_msec, 0)

func get_elapsed_run_time_text() -> String:
	var total_seconds := int(get_elapsed_run_time_msec() / 1000)
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	var seconds := total_seconds % 60

	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]
	return "%02d:%02d" % [minutes, seconds]

func apply_score_change(score_change: int, show_loss_indicator: bool = true) -> void:
	if not _run_active:
		return
	current_score = maxi(current_score + score_change, 0)
	score_changed.emit(current_score)
	score_update.emit(score_change)
	if show_loss_indicator and score_change < 0:
		score_loss_indicator.emit(abs(score_change))

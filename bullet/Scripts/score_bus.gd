extends Node

signal score_update(score_change) ##Positive score change value
signal score_loss_indicator(amount)

var starting_score: int = 77777
var score_per_shot: int = -250
var score_on_enemy_bullet_hit: int = -100
var score_on_spike_death: int = -500
var score_on_crush_death: int = -500
var passive_score_loss_per_second: int = 1
var shots_taken: int = 0
var reset_count: int = 0
var death_count: int = 0

var _passive_score_timer: float = 0.0
var _last_passive_score_tick_msec: int = 0
var _run_start_msec: int = 0
var _run_active := false

func _ready() -> void:
	_last_passive_score_tick_msec = Time.get_ticks_msec()

func _process(delta: float) -> void:
	if passive_score_loss_per_second <= 0:
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
	apply_score_change(starting_score, false)

func player_fired_shot() -> void:
	shots_taken += 1
	apply_score_change(score_per_shot)

func player_hit_by_enemy_bullet() -> void:
	apply_score_change(score_on_enemy_bullet_hit)

func register_player_death() -> void:
	death_count += 1

func player_died_to_spikes() -> void:
	register_player_death()
	apply_score_change(score_on_spike_death)

func player_died_to_crush() -> void:
	register_player_death()
	apply_score_change(score_on_crush_death)

func spend_score(amount: int) -> void:
	apply_score_change(-abs(amount))

func start_run() -> void:
	shots_taken = 0
	reset_count = 0
	death_count = 0
	_run_active = true
	_run_start_msec = Time.get_ticks_msec()
	_passive_score_timer = 0.0
	_last_passive_score_tick_msec = _run_start_msec

func reset_run_stats() -> void:
	shots_taken = 0
	reset_count = 0
	death_count = 0
	_run_start_msec = 0
	_run_active = false
	_passive_score_timer = 0.0
	_last_passive_score_tick_msec = Time.get_ticks_msec()

func is_run_active() -> bool:
	return _run_active

func register_level_reset() -> void:
	if not _run_active:
		return
	reset_count += 1

func get_elapsed_run_time_msec() -> int:
	if not _run_active or _run_start_msec <= 0:
		return 0
	return max(Time.get_ticks_msec() - _run_start_msec, 0)

func get_elapsed_run_time_text() -> String:
	var total_seconds := int(get_elapsed_run_time_msec() / 1000)
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	var seconds := total_seconds % 60

	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]
	return "%02d:%02d" % [minutes, seconds]

func apply_score_change(score_change: int, show_loss_indicator: bool = true) -> void:
	score_update.emit(score_change)
	if show_loss_indicator and score_change < 0:
		score_loss_indicator.emit(abs(score_change))

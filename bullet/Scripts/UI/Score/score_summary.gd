extends RefCounted

static func saying_for_score(score: int) -> String:
	if score >= 70000:
		return "I tip my hat to you"
	if score >= 60000:
		return "Well you surely ain't lackin'"
	if score >= 40000:
		return "Missed it by a hair"
	if score >= 20000:
		return "Well bless your heart"
	return "If you find yourself in a hole, first to do is stop diggin'"

static func format_time(time_msec: int) -> String:
	var total_seconds := time_msec / 1000
	return "%02d:%02d:%02d" % [total_seconds / 3600, (total_seconds % 3600) / 60, total_seconds % 60]

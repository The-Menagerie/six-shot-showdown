extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _check_button_shadow(button: Button) -> void:
	var shadow := button.get_node("TextShadow") as Label
	_check(shadow.text == button.text, "Button shadows should display the exact button text")
	_check(shadow.size.is_equal_approx(button.size), "Button shadows should match their button's bounds after layout")
	_check((shadow.get_global_rect().position - button.get_global_rect().position).is_equal_approx(Vector2(3, 3)), "Button shadows should stay three pixels behind their text")

func _run_tests() -> void:
	# Use an isolated progress file so testing never changes the player's unlocks.
	var progress_path := "res://Tests/.act_progress_test_%d.cfg" % OS.get_process_id()
	var manager_script := GDScript.new()
	manager_script.source_code = FileAccess.get_file_as_string("res://ActManager.gd").replace("user://act_progress.cfg", progress_path)
	if manager_script.reload() != OK:
		quit(1)
		return
	var manager = manager_script.new()
	manager._ready()
	_check(manager.is_act_unlocked(1), "Act 1 should start unlocked")
	_check(not manager.is_act_unlocked(2) and not manager.is_act_unlocked(3), "Later acts should start locked")
	_check(not manager.is_act_unlocked(0) and not manager.is_act_unlocked(4), "Invalid acts should remain locked")
	manager.record_level_completion("res://Scenes/Levels/Act 2/act2_lvl12.tscn", "res://Scenes/Levels/Act 3/act3_lvl1.tscn")
	_check(manager.completed_acts == 0, "Act 2 cannot unlock Act 3 before Act 1 is complete")
	manager.record_level_completion("res://Scenes/Levels/Act 1/act1_lvl11.tscn", "res://Scenes/Levels/Act 1/act1_lvl12.tscn")
	_check(manager.completed_acts == 0, "Entering the final level does not complete the act")
	manager.record_level_completion("res://Scenes/Levels/Act 1/act1_lvl12.tscn", "res://Scenes/Levels/Act 2/act2_lvl1.tscn")
	_check(manager.is_act_unlocked(2) and not manager.is_act_unlocked(3), "Beating Act 1 should unlock only Act 2")
	var reloaded_manager = manager_script.new()
	reloaded_manager._ready()
	_check(reloaded_manager.completed_acts == 1, "Act 1 completion should persist")
	reloaded_manager.record_level_completion("res://Scenes/Levels/Act 2/act2_lvl12.tscn", "res://Scenes/Levels/Act 3/act3_lvl1.tscn")
	_check(reloaded_manager.is_act_unlocked(3), "Beating Act 2 should unlock Act 3")
	manager._ready()
	_check(manager.completed_acts == 2, "Act 2 completion should persist")
	manager.record_level_completion("res://Scenes/Levels/Act 1/act1_lvl12.tscn", "res://Scenes/Levels/Act 2/act2_lvl1.tscn")
	_check(manager.completed_acts == 2, "Replaying Act 1 should preserve later unlocks")
	var score_bus := root.get_node("ScoreBus")
	var original_shots: int = score_bus.shots_taken
	var original_resets: int = score_bus.reset_count
	var original_deaths: int = score_bus.death_count
	manager.begin_level("res://Scenes/Levels/Act 1/act1_lvl1.tscn")
	score_bus.shots_taken += 3
	score_bus.reset_count += 2
	score_bus.death_count += 1
	score_bus.apply_score_change(-1500)
	manager.begin_level("res://Scenes/Levels/Act 1/act1_lvl1.tscn")
	manager.record_level_completion("res://Scenes/Levels/Act 1/act1_lvl12.tscn", "res://Scenes/Levels/Act 2/act2_lvl1.tscn")
	var stats: Dictionary = manager.get_act_stats(1)
	_check(stats.get("shots") == 3 and stats.get("resets") == 2 and stats.get("deaths") == 1, "First-level resets should preserve the act's counters")
	_check(stats.get("high_score") == score_bus.starting_score - 1500, "Scores should contain only the selected act's losses")
	reloaded_manager._ready()
	_check(reloaded_manager.get_act_stats(1) == stats, "Act stats should persist alongside unlocks")
	manager.begin_level("res://Scenes/Levels/Act 1/act1_lvl1.tscn")
	score_bus.apply_score_change(-2000)
	manager.record_level_completion("res://Scenes/Levels/Act 1/act1_lvl12.tscn", "res://Scenes/Levels/Act 2/act2_lvl1.tscn")
	_check(manager.get_act_stats(1).get("completions") == 2, "Replays should count as completions")
	_check(manager.get_act_stats(1).get("high_score") == stats.get("high_score"), "A worse replay should preserve the high score")
	_check(manager.get_act_stats(1).get("last_score") == score_bus.starting_score - 2000, "Latest reputation should be saved separately from the high score")
	var leaderboard_results: Array = manager.get_act_leaderboard(1)
	_check(leaderboard_results.size() == 2, "Both completions should be retained as leaderboard rows")
	_check(leaderboard_results[0]["reputation"] == score_bus.starting_score - 1500, "The best reputation should rank first")
	_check(leaderboard_results[0]["shots"] == 3 and leaderboard_results[1]["shots"] == 0, "Each row should keep its own counters")
	reloaded_manager._ready()
	_check(reloaded_manager.get_act_leaderboard(1) == leaderboard_results, "Leaderboard rows should persist across reloads")
	reloaded_manager.act_stats[1] = {"last_score": 500, "shots": 4, "resets": 2, "deaths": 1, "last_time_msec": 9000}
	_check(reloaded_manager.get_act_leaderboard(1)[0]["shots"] == 4, "Older saves should retain their latest run as a row")
	reloaded_manager.act_stats[1] = {"runs": [
		{"reputation": 500, "shots": 4, "resets": 2, "deaths": 1, "time_msec": 9000},
		{"reputation": 500, "shots": 5, "resets": 0, "deaths": 0, "time_msec": 8000}
	]}
	_check(reloaded_manager.get_act_leaderboard(1)[0]["time_msec"] == 8000, "Faster times should break reputation ties")
	manager.begin_level("res://Scenes/Levels/Act 2/act2_lvl1.tscn")
	score_bus.shots_taken += 1
	manager.record_level_completion("res://Scenes/Levels/Act 2/act2_lvl12.tscn", "res://Scenes/Levels/Act 3/act3_lvl1.tscn")
	_check(manager.get_act_stats(2).get("shots") == 1, "Act 2 should exclude Act 1's shots")
	manager.begin_level("res://Scenes/Levels/Act 3/act3_lvl1.tscn")
	manager.record_level_completion("res://Scenes/Levels/Act 3/act3_lvl12.tscn", "res://Scenes/UI/temp_score_scene.tscn")
	_check(manager.get_act_stats(3).get("completions") == 1, "Act 3 should record results at the scoreboard transition")
	manager.begin_level("res://Scenes/Levels/Act 1/act1_lvl1.tscn")
	manager.end_act_attempt()
	manager.record_level_completion("res://Scenes/Levels/Act 1/act1_lvl12.tscn", "res://Scenes/Levels/Act 2/act2_lvl1.tscn")
	_check(manager.get_act_stats(1).get("completions") == 2, "Abandoned attempts should not produce completed results")
	score_bus.shots_taken = original_shots
	score_bus.reset_count = original_resets
	score_bus.death_count = original_deaths

	var act_manager := root.get_node("ActManager")
	var original_completed_acts: int = act_manager.completed_acts
	var original_act_selected: bool = act_manager.ActSelected
	var original_stats: Dictionary = act_manager.act_stats.duplicate(true)
	act_manager.completed_acts = 0
	act_manager.ActSelected = false
	var menu = load("res://Scenes/act_select.tscn").instantiate()
	root.add_child(menu)
	var arrow_row = menu.get_node("MarginContainer/ColorRect/MarginContainer/VBoxContainer/HBoxContainer")
	arrow_row.get_node("RotRight").pressed.emit()
	_check(menu.selected_act == 2, "The right arrow should select the next act")
	arrow_row.get_node("RotLeft").pressed.emit()
	_check(menu.selected_act == 1, "The left arrow should select the previous act")
	arrow_row.get_node("RotLeft").pressed.emit()
	_check(menu.selected_act == 6, "The left arrow should wrap around the cylinder")
	menu.validate_data("left")
	menu.validate_data("left")
	menu.validate_data("left")
	_check(menu.selected_act == 3, "Navigation should skip the empty slots to Act 3")
	_check(menu.anim_player.speed_scale == 1.0, "Normal animation speed should return on reaching an act")
	menu.selected_act = 2
	menu.change_act_data(2)
	_check(menu.play_button.disabled, "Act 2's Play button should be disabled")
	_check("Beat Act 1" in menu.act_description.text, "Locked Act 2 should explain how to unlock it")
	menu._on_play_pressed()
	_check(not act_manager.ActSelected, "The Play handler should reject locked acts")
	act_manager.completed_acts = 1
	menu.change_act_data(2)
	_check(not menu.play_button.disabled, "Act 2's Play button should enable after Act 1")
	menu.selected_act = 3
	menu.change_act_data(3)
	_check(menu.play_button.disabled, "Act 3 should remain locked after Act 1")
	act_manager.completed_acts = 2
	menu.change_act_data(3)
	_check(not menu.play_button.disabled, "Act 3's Play button should enable after Act 2")
	act_manager.act_stats = manager.act_stats.duplicate(true)
	menu.selected_act = 1
	menu._on_stats_pressed()
	_check(is_instance_valid(menu.stats_screen) and menu.stats_screen.heading.text == "Act 1 Local Leaderboard", "Stats should open the selected act's leaderboard")
	_check("Completions: 2" in menu.stats_screen.records_label.text, "The score screen should display the selected act's results")
	var table: Tree = menu.stats_screen.leaderboard
	_check(table.columns == 5 and table.get_column_title(0).begins_with("Reputation") and table.get_column_title(4) == "Time", "The leaderboard should display the requested columns")
	var first_row := table.get_root().get_first_child()
	_check(first_row.get_text(0) == str(score_bus.starting_score - 1500), "The leaderboard should display the highest reputation first")
	_check(first_row.get_text(1) == "3" and first_row.get_text(2) == "2" and first_row.get_text(3) == "1", "Counters should align with the same completion's reputation")
	_check(first_row.get_next().get_text(0) == str(score_bus.starting_score - 2000), "The leaderboard should also display the latest completion")
	_check(menu.stats_screen.back_button.get_theme_color("font_focus_color") == menu.stats_screen.back_button.get_theme_color("font_color"), "Back should stay white when focused")
	_test_column_sorting(menu.stats_screen)
	menu.move_right()
	_check(menu.selected_act == 1, "Act navigation should stop while the score screen is open")
	menu.stats_screen.back_requested.emit()
	_check(not is_instance_valid(menu.stats_screen) and menu.selected_act == 1, "Back should return to the same selected act")
	arrow_row.get_node("RotRight").pressed.emit()
	_check(menu.selected_act == 2, "Arrows should work after closing the score screen")
	act_manager.act_stats = {}
	act_manager.completed_acts = 0
	menu.selected_act = 2
	menu._on_stats_pressed()
	_check("No completed runs" in menu.stats_screen.context_label.text, "Unrecorded acts should show an empty state")
	_check(menu.stats_screen.replay_button.disabled, "Locked acts should not be replayable from the score screen")
	menu.stats_screen._on_replay_pressed()
	_check(not act_manager.ActSelected, "Replay should reject locked acts")
	menu._on_stats_closed()
	act_manager.act_stats = original_stats
	act_manager.completed_acts = original_completed_acts
	act_manager.ActSelected = original_act_selected
	menu.free()
	await _test_arrow_clicks()
	_test_per_act_scoring(manager)
	await _test_paused_scoring()
	await _test_end_of_act_screens(manager)
	await _test_final_score_summary(manager)
	await _test_statistics_menu(manager)
	await _test_menu_credits()
	_test_profiles(manager, reloaded_manager)
	_test_profile_migration(manager_script, progress_path)
	manager.free()
	reloaded_manager.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(progress_path))
	print("Act unlock tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)

func _test_menu_credits() -> void:
	var live_manager := root.get_node("ActManager")
	var original_stats: Dictionary = live_manager.act_stats.duplicate(true)
	var original_completed: int = live_manager.completed_acts
	live_manager.act_stats = {}
	live_manager.completed_acts = 0
	var menu = load("res://Scenes/UI/MainMenu/menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	var button: Button = menu.get_node("CreditsButton")
	var button_rect := button.get_global_rect()
	_check(button.visible and button_rect.end.x > root.size.x * 0.9 and button_rect.end.y > root.size.y * 0.9, "Credits should be available in the main menu's bottom-right corner even for a new profile")
	_click_control(button)
	await menu.get_node("WoodenBlock").finished
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://Scenes/UI/MainMenu/credits.tscn", "The menu Credits button should open the shared credits scene")
	var credits = current_scene
	_check(credits.opened_from_menu and credits.skip_button.text == "Menu", "Menu credits should show Menu instead of Skip")
	credits.credit_tween.custom_step(10000.0)
	await process_frame
	_check(current_scene == credits and not credits.action_in_progress, "Menu credits should keep the completed credits visible until the player returns to the menu")
	_check(live_manager.act_stats.is_empty() and live_manager.completed_acts == 0, "Watching credits from the menu should not change profile progress")
	credits.skip_button.pressed.emit()
	await credits.get_node("WoodenBlock").finished
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://Scenes/UI/MainMenu/menu.tscn", "The Menu button should return from credits to the main menu")
	if current_scene != null:
		current_scene.free()
	live_manager.act_stats = original_stats
	live_manager.completed_acts = original_completed
	await process_frame

func _test_statistics_menu(manager: Node) -> void:
	var original_stats: Dictionary = manager.act_stats.duplicate(true)
	var menu_script := GDScript.new()
	menu_script.source_code = FileAccess.get_file_as_string("res://Scripts/MainMenu/menu.gd").replace("extends Control", "extends Control\nvar progress_manager: Node").replace("ActManager.", "progress_manager.")
	if menu_script.reload() != OK:
		_check(false, "The statistics menu should compile")
		return
	manager.act_stats.erase(3)
	var menu = load("res://Scenes/UI/MainMenu/menu.tscn").instantiate()
	menu.set_script(menu_script)
	menu.progress_manager = manager
	root.add_child(menu)
	await process_frame
	var statistics_button: Button = menu.get_node("ButtonContainer/Statistics")
	_check(not manager.has_completed_game() and not statistics_button.visible, "Statistics should stay hidden until Act 3 is beaten, even when it is unlocked")
	menu.statistics_button_pressed()
	_check(not menu.menu_action_in_progress, "Statistics should reject navigation before the game is completed")
	manager.act_stats = original_stats.duplicate(true)
	menu._on_profile_changed()
	_check(manager.has_completed_game() and statistics_button.visible, "A completed active profile should show Statistics")
	_check(statistics_button.get_index() == menu.get_node("ButtonContainer/Continue").get_index() + 1, "Statistics should appear directly below Continue")
	manager.act_stats = {}
	menu._on_profile_changed()
	_check(not statistics_button.visible, "Changing to an empty profile or deleting save data should hide Statistics")
	manager.act_stats = original_stats.duplicate(true)
	menu._on_profile_changed()
	var live_manager := root.get_node("ActManager")
	var live_stats: Dictionary = live_manager.act_stats.duplicate(true)
	live_manager.act_stats = original_stats.duplicate(true)
	current_scene = menu
	statistics_button.pressed.emit()
	await menu.get_node("WoodenBlock").finished
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://Scenes/UI/MainMenu/statistics.tscn", "Statistics should open the shared final score page")
	var page = current_scene
	var score = page.get_node("CanvasLayer/Panel/Container/Score")
	_check_button_shadow(page.get_node("CanvasLayer/Panel/Container/Quit"))
	var summary: Dictionary = manager.get_final_score_summary(true)
	_check(score.opened_from_menu and score.text == "%d Reputation" % summary["reputation"], "Statistics should use the active profile's saved totals")
	_check(score.score_tabs.current_tab == 0, "Statistics should open on Recent")
	_check(not page.get_node("CanvasLayer/Panel/Container/Start").visible and page.get_node("CanvasLayer/Panel/Container/Quit").text == "Back to Main Menu", "Statistics should offer a return to the menu")
	score.score_tabs.current_tab = 0
	var recent: Dictionary = manager.get_final_score_summary(true)
	_check(score.text == "%d Reputation" % recent["reputation"], "The Statistics page should retain the Recent tab")
	var left_rect: Rect2 = page.get_node("Navigation/Left").get_global_rect()
	var right_rect: Rect2 = page.get_node("Navigation/Right").get_global_rect()
	var title_rect: Rect2 = page.get_node("CanvasLayer/Panel/Container/Congrats").get_global_rect()
	_check(absf(left_rect.get_center().y - title_rect.get_center().y) < 1.0 and absf(right_rect.get_center().y - title_rect.get_center().y) < 1.0, "The navigation arrows should align with the statistics title")
	for act in range(1, 4):
		_click_control(page.get_node("Navigation/Right"))
		await process_frame
		_check(page.selected_page == act and page.act_screen.selected_act == act, "The right arrow should cycle through every act leaderboard")
		_check(page.act_screen.results == live_manager.get_act_leaderboard(act), "Statistics should show the active profile's saved leaderboard for Act %d" % act)
		_check(page.act_screen.heading.text == "Act %d Local Leaderboard" % act, "The leaderboard should identify the selected act")
		_check_button_shadow(page.act_screen.back_button)
		_check(page.get_node("Navigation/Left").get_global_rect() == left_rect and page.get_node("Navigation/Right").get_global_rect() == right_rect, "The arrow positions should stay fixed when switching statistics pages")
		_check(absf(page.act_screen.heading.get_global_rect().get_center().y - left_rect.get_center().y) < 1.0, "Act leaderboard titles should use the same header height as overall statistics")
		_check(page.act_screen.heading.get_minimum_size().x < right_rect.position.x - left_rect.end.x, "Every act title should fit between the fixed arrows")
		_check(not page.summary_layer.visible and not score.is_processing_unhandled_input(), "Only the current leaderboard should handle back navigation")
		if act == 1:
			_test_column_sorting(page.act_screen)
	_click_control(page.get_node("Navigation/Right"))
	await process_frame
	_check(page.selected_page == 0 and page.act_screen == null and page.summary_layer.visible, "The right arrow should wrap back to the overall statistics")
	_check(score.score_tabs.current_tab == 0 and score.text == "%d Reputation" % recent["reputation"], "Returning to the overall statistics should preserve the Recent selection")
	_click_control(page.get_node("Navigation/Left"))
	await process_frame
	_check(page.selected_page == 3, "The left arrow should wrap from the overall statistics to Act 3")
	_click_control(page.get_node("Navigation/Left"))
	await process_frame
	_check(page.selected_page == 2, "The left arrow should navigate backward through the acts")
	var act_screen = page.act_screen
	_check(act_screen.back_button.text == "Back to Main Menu", "Statistics leaderboards should offer a return to the main menu")
	act_screen.back_button.pressed.emit()
	await act_screen.get_node("WoodenBlock").finished
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://Scenes/UI/MainMenu/menu.tscn", "Back to Main Menu should return from Statistics without exiting the game")
	if current_scene != null:
		_check(current_scene.get_node("ButtonContainer/Statistics").visible, "Statistics should remain available after returning to the menu")
		current_scene.free()
	live_manager.act_stats = live_stats
	manager.act_stats = original_stats
	await process_frame

func _test_final_score_summary(manager: Node) -> void:
	var original_stats: Dictionary = manager.act_stats.duplicate(true)
	var saved_manager = manager.get_script().new()
	saved_manager._ready()
	_check(saved_manager.get_final_score_summary(true) == manager.get_final_score_summary(true), "Recent summaries should survive saving and reloading")
	saved_manager.free()
	manager.act_stats = {
		1: {"runs": [
			{"reputation": 60000, "shots": 5, "resets": 2, "deaths": 1, "time_msec": 70000},
			{"reputation": 55000, "shots": 50, "resets": 20, "deaths": 10, "time_msec": 200000}
		]},
		2: {"runs": [
			{"reputation": 40000, "shots": 3, "resets": 1, "deaths": 2, "time_msec": 15000},
			{"reputation": 40000, "shots": 7, "resets": 4, "deaths": 3, "time_msec": 12000}
		]},
		3: {"runs": [{"reputation": 8000, "shots": 9, "resets": 0, "deaths": 2, "time_msec": 63000}]}
	}
	manager.act_stats[1].merge({"last_score": 55000, "shots": 50, "resets": 20, "deaths": 10, "last_time_msec": 200000})
	manager.act_stats[2].merge({"last_score": 40000, "shots": 7, "resets": 4, "deaths": 3, "last_time_msec": 12000})
	manager.act_stats[3].merge({"last_score": 8000, "shots": 9, "resets": 0, "deaths": 2, "last_time_msec": 63000})
	var summary: Dictionary = manager.get_final_score_summary()
	_check(summary["reputation"] == 108000, "The final score should add each act's best reputation, excluding worse replays")
	_check(summary["shots"] == 21 and summary["resets"] == 6 and summary["deaths"] == 6 and summary["time_msec"] == 145000, "Final counters and time should come from the same three best runs, using the faster tied result")
	var recent: Dictionary = manager.get_final_score_summary(true)
	_check(recent["reputation"] == 103000 and recent["shots"] == 66 and recent["resets"] == 24 and recent["deaths"] == 15 and recent["time_msec"] == 275000, "Recent should combine each act's latest completion and its matching stats, including worse replays")
	var live_manager := root.get_node("ActManager")
	var live_stats: Dictionary = live_manager.act_stats.duplicate(true)
	live_manager.act_stats = manager.act_stats.duplicate(true)
	var page = load("res://Scenes/UI/temp_score_scene.tscn").instantiate()
	root.add_child(page)
	await process_frame
	var score = page.get_node("CanvasLayer/Panel/Container/Score")
	_check_button_shadow(page.get_node("CanvasLayer/Panel/Container/Start"))
	_check_button_shadow(page.get_node("CanvasLayer/Panel/Container/Quit"))
	_check(score.score_tabs.current_tab == 0 and score.text == "103000 Reputation" and score.stats_label.text == "Shots: 66 | Resets: 24 | Deaths: 15 | Time: 00:04:35", "The final score page should open on Recent with its matching totals")
	score.score_tabs.current_tab = 1
	_check(score.text == "108000 Reputation", "The final page should display the combined reputation")
	_check(score.stats_label.text == "Shots: 21 | Resets: 6 | Deaths: 6 | Time: 00:02:25", "The final page should display combined counters and format the summed time")
	for index in range(3):
		var expected_reputation: int = [60000, 40000, 8000][index]
		_check(score.act_scores_container.get_child(index).text == "Act %d Best\n%d Reputation" % [index + 1, expected_reputation], "Each act's best reputation should appear separately")
	var tabs: TabBar = score.score_tabs
	_check(tabs.get_tab_count() == 2 and tabs.get_tab_title(0) == "Recent" and tabs.get_tab_title(1) == "Best", "Recent and Best tabs should both remain available")
	_check(tabs.get_index() == page.get_node("CanvasLayer/Panel/Container/HSeparator").get_index() + 1, "The score tabs should sit directly below the divider")
	_check(tabs.get_tab_rect(0).size.x > 0 and tabs.get_tab_rect(1).end.x <= tabs.size.x, "Both score tabs should fit visibly side by side without clipping")
	tabs.current_tab = 0
	_check(score.text == "103000 Reputation" and score.stats_label.text == "Shots: 66 | Resets: 24 | Deaths: 15 | Time: 00:04:35", "Switching to Recent should refresh the score and every combined stat")
	_check(score.act_scores_container.get_child(0).text == "Act 1 Recent\n55000 Reputation", "Recent should show the latest act reputation even when it is below the best")
	tabs.current_tab = 1
	_check(score.text == "108000 Reputation" and score.stats_label.text == "Shots: 21 | Resets: 6 | Deaths: 6 | Time: 00:02:25", "Switching back to Best should restore the original best results")
	var panel = page.get_node("CanvasLayer/Panel")
	var container = panel.get_node("Container")
	_check(container.get_combined_minimum_size().x <= panel.size.x and container.get_combined_minimum_size().y <= panel.size.y, "The expanded final summary should fit inside its panel")
	current_scene = page
	page.get_node("CanvasLayer/Panel/Container/Quit").pressed.emit()
	await page.get_node("WoodenBlock").finished
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://Scenes/UI/MainMenu/menu.tscn", "Return to Main Menu should leave the final score screen without quitting the game")
	if current_scene != null:
		current_scene.free()
	live_manager.act_stats = live_stats
	manager.act_stats = {}
	summary = manager.get_final_score_summary()
	_check(summary["reputation"] == 0 and summary["time_msec"] == 0 and not summary["acts"][0]["completed"], "An empty profile should not inherit another profile's results")
	recent = manager.get_final_score_summary(true)
	_check(recent["reputation"] == 0 and not recent["acts"][0]["completed"], "Recent should also show unplayed acts for an empty profile")
	manager.act_stats = {1: {"last_score": 1234, "shots": 2, "resets": 1, "deaths": 0, "last_time_msec": 4567}}
	summary = manager.get_final_score_summary()
	_check(summary["reputation"] == 1234 and summary["shots"] == 2 and summary["time_msec"] == 4567 and not summary["acts"][2]["completed"], "Older saves and unplayed acts should produce a usable summary")
	_check(manager.get_final_score_summary(true) == summary, "Recent should support older saves containing only the latest completion")
	manager.act_stats[1]["last_score"] = 0
	recent = manager.get_final_score_summary(true)
	_check(recent["acts"][0]["completed"] and recent["acts"][0]["reputation"] == 0 and recent["shots"] == 2, "A zero-reputation completion should still appear as a completed Recent run")
	manager.act_stats = original_stats

func _test_paused_scoring() -> void:
	var score_bus := root.get_node("ScoreBus")
	score_bus.start_run()
	score_bus._passive_score_timer = 0.75
	var score_before_pause: int = score_bus.current_score
	paused = true
	var paused_time: int = score_bus.get_elapsed_run_time_msec()
	await create_timer(1.1, true, false, true).timeout
	_check(score_bus.current_score == score_before_pause, "Pausing should stop the reputation countdown")
	_check(score_bus.get_elapsed_run_time_msec() == paused_time, "Paused time should not count toward the act completion time")
	paused = false
	await process_frame
	score_bus._process(0.0)
	_check(score_bus.current_score == score_before_pause, "Resuming should not deduct reputation for time spent paused")
	_check(score_bus.get_elapsed_run_time_msec() - paused_time < 200, "Resuming should exclude the entire pause from the act timer")
	_check(score_bus._passive_score_timer >= 0.75, "Pausing should preserve progress toward the next countdown tick")
	score_bus._last_passive_score_tick_msec -= 1000
	score_bus._process(1.0)
	_check(score_bus.current_score == score_before_pause - score_bus.passive_score_loss_per_second, "The countdown should resume its normal deductions after unpausing")
	score_bus.finish_run()

func _test_end_of_act_screens(manager: Node) -> void:
	# Route completions through the real game manager using the isolated save.
	var game_script := GDScript.new()
	game_script.source_code = FileAccess.get_file_as_string("res://Scripts/game_manager.gd").replace("extends Node2D", "extends Node2D\nvar progress_manager: Node").replace("ActManager.", "progress_manager.")
	if game_script.reload() != OK:
		_check(false, "End-of-act game manager should compile")
		return
	var score_bus := root.get_node("ScoreBus")
	for act in range(1, 4):
		var transition: Array = manager.ACT_COMPLETION_TRANSITIONS[act]
		_check(manager.get_completed_act_for_transition(transition[0], transition[1]) == act, "Every act's final exit should show its result screen")
		_check(manager.get_completed_act_for_transition(transition[1], transition[0]) == 0, "Other transitions should not complete an act")
		manager.begin_level("res://Scenes/Levels/Act %d/act%d_lvl1.tscn" % [act, act])
		score_bus.apply_score_change(-act * 100)
		var expected_score: int = score_bus.current_score
		var game = game_script.new()
		game.progress_manager = manager
		game.level_fade_in_duration = 0.0
		var music := AudioStreamPlayer.new()
		music.name = "AudioStreamPlayer"
		music.stream = load("res://Assets/Music/CowboyGameSong.mp3")
		game.add_child(music)
		var canvas := CanvasLayer.new()
		canvas.name = "CanvasLayer"
		game.add_child(canvas)
		var bullet_overlay := ColorRect.new()
		bullet_overlay.name = "BulletTimeOverlay"
		canvas.add_child(bullet_overlay)
		var overlay := ColorRect.new()
		overlay.name = "TransitionOverlay"
		canvas.add_child(overlay)
		var transition_label := Label.new()
		transition_label.name = "TransitionText"
		overlay.add_child(transition_label)
		var completed_level := Node2D.new()
		completed_level.scene_file_path = transition[0]
		game.add_child(completed_level)
		game.current_level = completed_level
		root.add_child(game)
		game.transition_to_level(load(transition[1]), 0.0)
		for frame in range(120):
			await process_frame
			if game._is_end_of_act_screen() and not game.is_level_transition_active:
				break
		_check(game._is_end_of_act_screen(), "Act %d should stop at the black result screen" % act)
		if not game._is_end_of_act_screen():
			game.free()
			return
		var screen = game.current_level
		_check(screen.title_label.text == "End of Act %d" % act, "The result title should identify the completed act")
		_check(screen.reputation_label.text == "Reputation: %d" % expected_score, "The result screen should show the frozen act reputation")
		var expected_next: String = "res://Scenes/UI/credits.tscn" if act == 3 else transition[1]
		_check(screen.next_scene.resource_path == expected_next, "Act 3 should continue to credits, while other acts continue to their next act")
		_check(not game.is_level_transition_active, "Result buttons should be usable as soon as the screen appears")
		_check(not score_bus.is_run_active(), "The result screen should not accumulate more score losses")
		_check(manager.get_act_stats(act).get("last_score") == expected_score, "The displayed score should match the saved leaderboard result")
		# Earlier acts use a dummy scene; Act 3 exercises the real credits flow.
		if act != 3:
			var target := PackedScene.new()
			var target_node := Node2D.new()
			target.pack(target_node)
			target_node.free()
			screen.next_scene = target
		screen.continue_button.pressed.emit()
		await screen.get_node("WoodenBlock").finished
		for frame in range(120):
			await process_frame
			if not game._is_end_of_act_screen() and not game.is_level_transition_active:
				break
		_check(not game._is_end_of_act_screen(), "Continue should leave the result screen")
		if act == 3:
			_check(game.current_level.scene_file_path == "res://Scenes/UI/credits.tscn", "Act 3 Continue should display credits before the final scores")
			var credits = game.current_level
			var music_manager := root.get_node("MusicManager")
			_check(not game.music_player.playing and music_manager.music_player.playing and music_manager.current_stream.resource_path == "res://Assets/Music/CowboyMenuSong.mp3", "Credits should replace game music with the menu song")
			game._on_music_finished()
			_check(not game.music_player.playing, "Game music should not restart while the credits are displayed")
			_check(not credits.credit_lines.is_empty() and credits.line_labels[0].text == credits.credit_lines[0], "Credits should start with the first authored line instead of placeholder text")
			_check(game._is_post_act_screen() and not score_bus.is_run_active(), "Credits should block gameplay controls and keep completed stats frozen")
			var completions: int = manager.get_act_stats(3)["completions"]
			var skip_rect: Rect2 = credits.skip_button.get_global_rect()
			_check(skip_rect.end.x > root.size.x * 0.9 and skip_rect.end.y > root.size.y * 0.9, "Skip should appear in the bottom-right corner")
			credits.skip_button.pressed.emit()
			await credits.get_node("WoodenBlock").finished
			for frame in range(180):
				await process_frame
				if game.current_level.scene_file_path == transition[1] and not game.is_level_transition_active:
					break
			_check(game.current_level.scene_file_path == transition[1], "Skip should advance to the final score page")
			_check(manager.get_act_stats(3)["completions"] == completions and score_bus.current_score == expected_score, "Credits should not save duplicate completions or alter reputation")
			game.change_level(load("res://Scenes/UI/credits.tscn"))
			await process_frame
			await process_frame
			credits = game.current_level
			credits.credit_tween.custom_step(0.3)
			_check(credits.line_labels[0].modulate.a > 0.0 and credits.line_labels[0].modulate.a < 1.0, "Each credit line should fade in gradually")
			credits.credit_tween.custom_step(3.1)
			_check(is_equal_approx(credits.line_labels[0].modulate.a, 1.0) and credits.line_labels[1].modulate.a > 0.0, "Revealing the next credit should keep the previous line visible")
			_check(credits.line_labels[1].get_global_rect().position.y > credits.line_labels[0].get_global_rect().position.y, "Credit lines should reveal downward in their original order")
			credits.credit_tween.custom_step(10000.0)
			await process_frame
			await process_frame
			_check(game.current_level == credits and not game.is_level_transition_active and not credits.action_in_progress, "Completed credits should wait on screen instead of automatically advancing")
			_check(credits.skip_button.text == "Continue", "Skip should become Continue after all credits are revealed")
			credits.skip_button.pressed.emit()
			await credits.get_node("WoodenBlock").finished
			for frame in range(180):
				await process_frame
				if game.current_level.scene_file_path == transition[1] and not game.is_level_transition_active:
					break
			_check(game.current_level.scene_file_path == transition[1], "Pressing Continue after the credits should advance to the final score page")
			_check(music_manager.music_player.playing and not game.music_player.playing, "Menu music should continue into the final score screen")
			game.current_level.scene_file_path = "res://Scenes/Levels/Act 1/act1_lvl1.tscn"
			game._emit_level_changed()
			_check(game.music_player.playing and not music_manager.music_player.playing, "Starting another game should restore game music and stop the menu song")
		game.free()
		await process_frame
	var menu_screen = load("res://Scenes/UI/end_of_act.tscn").instantiate()
	menu_screen.configure_act_result(2, score_bus.current_score, null)
	root.add_child(menu_screen)
	_check(menu_screen.continue_button.disabled, "A result screen without a next scene should disable Continue")
	menu_screen.main_menu_button.pressed.emit()
	await menu_screen.get_node("WoodenBlock").finished
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://Scenes/UI/MainMenu/menu.tscn", "Main Menu should return to the starting menu")
	if current_scene != null:
		current_scene.free()
	menu_screen.free()
	await process_frame

func _test_per_act_scoring(manager: Node) -> void:
	var score_bus := root.get_node("ScoreBus")
	var game_manager = load("res://Scripts/game_manager.gd").new()
	var hud = load("res://Scripts/score_label.gd").new()
	root.add_child(hud)
	hud.game_manager = game_manager
	game_manager.level_changed.connect(hud._on_level_changed)
	manager.begin_level("res://Scenes/Levels/Act 2/act2_lvl1.tscn")
	game_manager.level_changed.emit("res://Scenes/Levels/Act 2/act2_lvl1.tscn")
	_check(score_bus.is_run_active() and hud.score == score_bus.starting_score and hud.score_enabled, "Starting Act 2 directly should reset and display its reputation")
	_check(score_bus.shots_taken == 0 and score_bus.reset_count == 0 and score_bus.death_count == 0, "Starting an act should clear all counters")
	score_bus.player_fired_shot()
	score_bus.register_level_reset()
	score_bus.player_died_to_spikes()
	score_bus.player_burning()
	score_bus._run_start_msec = Time.get_ticks_msec() - 5000
	var score_before_reset: int = score_bus.current_score
	manager.begin_level("res://Scenes/Levels/Act 2/act2_lvl1.tscn")
	game_manager.level_changed.emit("res://Scenes/Levels/Act 2/act2_lvl1.tscn")
	_check(score_bus.current_score == score_before_reset and score_bus.shots_taken == 1 and score_bus.reset_count == 1 and score_bus.death_count == 1, "Restarting an act's first level should preserve that attempt's stats")
	manager.record_level_completion("res://Scenes/Levels/Act 2/act2_lvl12.tscn", "res://Scenes/Levels/Act 3/act3_lvl1.tscn")
	var finished_time: int = score_bus.get_elapsed_run_time_msec()
	_check(not score_bus.is_run_active() and finished_time >= 5000, "Completing an act should freeze its timer")
	var completed: Dictionary = manager.get_act_stats(2)
	_check(completed["last_score"] == hud.score and completed["shots"] == 1 and completed["resets"] == 1 and completed["deaths"] == 1, "Saved results should match the act's displayed reputation and counters")
	score_bus._last_passive_score_tick_msec -= 3000
	score_bus._process(3.0)
	score_bus.player_fired_shot()
	_check(score_bus.current_score == score_before_reset and score_bus.shots_taken == 1 and score_bus.get_elapsed_run_time_msec() == finished_time, "Completed stats should not change during transitions or on the end screen")
	manager.begin_level("res://Scenes/Levels/Act 3/act3_lvl1.tscn")
	game_manager.level_changed.emit("res://Scenes/Levels/Act 3/act3_lvl1.tscn")
	_check(hud.score == score_bus.starting_score and score_bus.shots_taken == 0 and score_bus.reset_count == 0 and score_bus.death_count == 0 and score_bus.burn_time == 0, "Transitioning to Act 3 should reset reputation and every counter")
	_check(score_bus.get_elapsed_run_time_msec() < 1000, "The new act should start a fresh timer")
	score_bus.player_fired_shot()
	manager.begin_level("res://Scenes/Levels/Act 3/act3_lvl2.tscn")
	game_manager.level_changed.emit("res://Scenes/Levels/Act 3/act3_lvl2.tscn")
	_check(score_bus.shots_taken == 1 and hud.score == score_bus.starting_score + score_bus.score_per_shot, "Moving between levels within an act should preserve its stats")
	score_bus.apply_score_change(-score_bus.starting_score * 2)
	manager.record_level_completion("res://Scenes/Levels/Act 3/act3_lvl12.tscn", "res://Scenes/UI/temp_score_scene.tscn")
	_check(hud.score == 0 and manager.get_act_stats(3)["last_score"] == 0, "HUD and saved reputation should share the same zero floor")
	hud.free()
	game_manager.free()

func _test_profiles(manager: Node, reloaded_manager: Node) -> void:
	var score_bus := root.get_node("ScoreBus")
	var original_stats: Dictionary = manager.act_stats.duplicate(true)
	_check(manager.active_profile == 1, "Existing data should start in Profile 1")
	_check(manager.select_profile(2) == OK and manager.act_stats.is_empty() and manager.completed_acts == 0, "Profile 2 should start empty")
	manager.begin_level("res://Scenes/Levels/Act 1/act1_lvl1.tscn")
	score_bus.apply_score_change(-1000)
	manager.record_level_completion("res://Scenes/Levels/Act 1/act1_lvl12.tscn", "res://Scenes/Levels/Act 2/act2_lvl1.tscn")
	var second_profile: Dictionary = manager.get_profile_data(2)
	_check(manager.select_profile(3) == OK and manager.act_stats.is_empty() and manager.completed_acts == 0, "Profile 3 should start empty")
	_check(manager.select_profile(1) == OK and manager.act_stats == original_stats and manager.completed_acts == 2, "Returning to Profile 1 should restore its unlocks and rows")
	reloaded_manager._ready()
	_check(reloaded_manager.active_profile == 1 and reloaded_manager.get_profile_data(2) == second_profile, "Slot data and the active profile should persist")
	_check(manager.select_profile(0) == ERR_INVALID_PARAMETER and manager.delete_profile(4) == ERR_INVALID_PARAMETER, "Invalid slot numbers should be rejected")
	var profile_button = load("res://Scenes/UI/MainMenu/profile_menu.tscn").instantiate()
	root.add_child(profile_button)
	profile_button.progress_manager = manager
	profile_button.pressed.emit()
	_check(profile_button.profiles_dialog.visible and profile_button.slots.get_child_count() == 9, "Profiles should open with three selection and deletion rows")
	profile_button.slots.get_node("Delete2").pressed.emit()
	_check(profile_button.confirmation.visible and profile_button.confirmation.get_ok_button().disabled, "Delete should require confirmation")
	for invalid_text in ["", "confirm", "CONFIR", "CONFIRMX", " CONFIRM", "CONFIRM "]:
		profile_button.confirmation_input.text = invalid_text
		profile_button.confirmation_input.text_changed.emit(invalid_text)
		_check(profile_button.confirmation.get_ok_button().disabled, "Deletion should reject '%s'" % invalid_text)
		profile_button.confirmation.confirmed.emit()
		_check(manager.get_profile_data(2) == second_profile, "Invalid confirmation must keep the target profile")
	profile_button.confirmation_input.text = "CONFIRM"
	profile_button.confirmation_input.text_changed.emit("CONFIRM")
	_check(not profile_button.confirmation.get_ok_button().disabled, "CONFIRM should enable Delete")
	profile_button.confirmation.canceled.emit()
	profile_button.confirmation.hide()
	_check(manager.get_profile_data(2) == second_profile, "Cancel must keep the profile")
	profile_button.slots.get_node("Delete2").pressed.emit()
	_check(profile_button.confirmation_input.text.is_empty() and profile_button.confirmation.get_ok_button().disabled, "Each deletion should require a fresh confirmation")
	profile_button.confirmation_input.text = "CONFIRM"
	profile_button.confirmation_input.text_changed.emit("CONFIRM")
	profile_button.confirmation.confirmed.emit()
	_check(manager.get_profile_data(2).is_empty(), "Confirmed deletion should empty only Profile 2")
	_check(manager.act_stats == original_stats and manager.completed_acts == 2, "Deleting another slot should preserve the active profile")
	manager.ActSelected = true
	manager.SelectedAct = load("res://Scenes/Levels/Act 3/act3_lvl1.tscn")
	manager.begin_level("res://Scenes/Levels/Act 3/act3_lvl1.tscn")
	profile_button.slots.get_node("Delete1").pressed.emit()
	profile_button.confirmation_input.text = "CONFIRM"
	profile_button.confirmation_input.text_changed.emit("CONFIRM")
	profile_button.confirmation.confirmed.emit()
	_check(manager.act_stats.is_empty() and manager.completed_acts == 0, "Deleting the active profile should clear records and re-lock acts")
	_check(not manager.ActSelected and manager.SelectedAct == null and manager._active_act == 0, "Deleting the active profile should clear its pending attempt")
	reloaded_manager._ready()
	_check(reloaded_manager.act_stats.is_empty() and reloaded_manager.completed_acts == 0 and reloaded_manager.get_profile_data(2).is_empty(), "Profile deletions should persist")
	profile_button.slots.get_node("Select3").pressed.emit()
	_check(manager.active_profile == 3 and profile_button.text == "Profile 3", "Select should activate and label the chosen slot")
	_check(not profile_button.profiles_dialog.visible, "Selecting a profile should return to the menu")
	reloaded_manager._ready()
	_check(reloaded_manager.active_profile == 3, "The selected slot should persist across restarts")
	profile_button.free()
	for scene_path in ["res://Scenes/UI/MainMenu/options.tscn", "res://Scenes/UI/PauseMenu/options_pause_menu.tscn"]:
		var settings = load(scene_path).instantiate()
		_check(not settings.has_node("OptionsContainer/ButtonContainer/ResetActLeaderboards"), "Settings should no longer offer save reset")
		settings.free()

func _test_profile_migration(manager_script: GDScript, progress_path: String) -> void:
	var legacy_path := progress_path + ".legacy"
	var legacy := ConfigFile.new()
	legacy.set_value("progress", "completed_acts", 1)
	var legacy_stats := {1: {"last_score": 7000, "shots": 2, "resets": 1, "deaths": 0, "last_time_msec": 1000}}
	legacy.set_value("progress", "act_stats", legacy_stats)
	_check(legacy.save(legacy_path) == OK, "The legacy fixture should save")
	var legacy_script := GDScript.new()
	legacy_script.source_code = manager_script.source_code.replace(progress_path, legacy_path)
	_check(legacy_script.reload() == OK, "The migration fixture should compile")
	var migrated = legacy_script.new()
	migrated._ready()
	_check(migrated.active_profile == 1 and migrated.completed_acts == 1 and migrated.act_stats == legacy_stats, "Original progress should migrate to Profile 1")
	_check(migrated.get_profile_data(2).is_empty() and migrated.get_profile_data(3).is_empty(), "Other profiles should be empty after migration")
	migrated.select_profile(2)
	migrated.select_profile(1)
	migrated._ready()
	_check(migrated.act_stats == legacy_stats and migrated.completed_acts == 1, "Migration should preserve data when switching slots and reloading")
	migrated.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))

func _test_arrow_clicks() -> void:
	var main_menu = load("res://Scenes/UI/MainMenu/menu.tscn").instantiate()
	root.add_child(main_menu)
	await process_frame
	main_menu.ActSlider.play("act_select_slide")
	main_menu.ActSlider.seek(1.0, true)
	main_menu.ActSlider.stop(true)
	await process_frame
	var act_select = main_menu.ActSelect
	var arrow_row = act_select.get_node("MarginContainer/ColorRect/MarginContainer/VBoxContainer/HBoxContainer")
	_click_control(arrow_row.get_node("RotRight"))
	_check(act_select.selected_act == 2, "Clicking the right arrow in the starting menu should change acts")
	_click_control(arrow_row.get_node("RotLeft"))
	_check(act_select.selected_act == 1, "Clicking the left arrow in the starting menu should change acts")
	main_menu.get_node("ProfileButton").pressed.emit()
	_check(not act_select.is_processing(), "Opening Profiles should pause act navigation")
	var profile_menu = main_menu.get_node("ProfileButton")
	profile_menu.profiles_dialog.confirmed.emit()
	profile_menu.profiles_dialog.hide()
	_check(act_select.is_processing(), "Closing Profiles should resume act navigation")
	act_select.move_right()
	main_menu._on_profile_changed()
	_check(act_select.selected_act == 1 and act_select.cylinder_rotator.rotation_degrees == 0.0, "Changing profiles should refresh the act selector from Act 1")
	main_menu.free()

func _test_column_sorting(screen: Control) -> void:
	screen.results.assign([
		{"reputation": 100, "shots": 10, "resets": 1, "deaths": 2, "time_msec": 100000},
		{"reputation": 20, "shots": 2, "resets": 10, "deaths": 1, "time_msec": 9000},
		{"reputation": 9, "shots": 5, "resets": 2, "deaths": 10, "time_msec": 10000}
	])
	screen._refresh_leaderboard()
	var selected_result: Dictionary = screen.leaderboard.get_selected().get_metadata(0)
	for column in range(5):
		screen.leaderboard.column_title_clicked.emit(column, MOUSE_BUTTON_LEFT)
		if not screen.sort_ascending:
			screen.leaderboard.column_title_clicked.emit(column, MOUSE_BUTTON_LEFT)
		var key: String = screen.COLUMN_KEYS[column]
		_check(screen.results[0][key] <= screen.results[1][key] and screen.results[1][key] <= screen.results[2][key], "Column %d should sort numerically ascending" % column)
		screen.leaderboard.column_title_clicked.emit(column, MOUSE_BUTTON_LEFT)
		_check(screen.results[0][key] >= screen.results[1][key] and screen.results[1][key] >= screen.results[2][key], "Column %d should toggle to descending" % column)
		_check(screen.leaderboard.get_selected().get_metadata(0) == selected_result, "Sorting should preserve the selected run")
	var previous_order: Array = screen.results.duplicate(true)
	screen.leaderboard.column_title_clicked.emit(0, MOUSE_BUTTON_RIGHT)
	_check(screen.results == previous_order, "Right-clicking should leave the sort order unchanged")

func _click_control(button: Control) -> void:
	var click_position := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = click_position
	motion.global_position = click_position
	root.push_input(motion, true)
	var hovered := root.gui_get_hovered_control()
	_check(hovered == button, "Arrow hover blocked at %s by %s" % [click_position, hovered.get_path() if hovered != null else "nothing"])
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = click_position
		click.global_position = click_position
		root.push_input(click, true)

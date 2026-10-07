extends Button

signal opened
signal closed
signal profile_changed

var progress_manager: Node = ActManager
var profile_to_delete := 0

@onready var profiles_dialog: AcceptDialog = $Profiles
@onready var slots: GridContainer = $Profiles/Content/Slots
@onready var status_label: Label = $Profiles/Content/Status
@onready var confirmation: ConfirmationDialog = $Profiles/Confirmation
@onready var warning_label: Label = $Profiles/Confirmation/Content/Warning
@onready var confirmation_input: LineEdit = $Profiles/Confirmation/Content/ConfirmationInput
@onready var error_label: Label = $Profiles/Confirmation/Content/ErrorLabel

func _ready() -> void:
	for slot in range(1, 4):
		slots.get_node("Select%d" % slot).pressed.connect(_on_select_pressed.bind(slot))
		slots.get_node("Delete%d" % slot).pressed.connect(_on_delete_pressed.bind(slot))
	confirmation.get_ok_button().disabled = true
	_refresh_profiles()

func _refresh_profiles() -> void:
	text = "Profile %d" % progress_manager.active_profile
	for slot in range(1, 4):
		var data: Dictionary = progress_manager.get_profile_data(slot)
		var stats: Dictionary = data.get("act_stats", {})
		var unlocked := int(data.get("completed_acts", 0)) + 1
		var summary := "New profile" if unlocked == 1 and stats.is_empty() else "Act %d unlocked" % unlocked
		slots.get_node("Slot%d" % slot).text = "Profile %d - %s" % [slot, summary]
		var select_button: Button = slots.get_node("Select%d" % slot)
		select_button.text = "Active" if slot == progress_manager.active_profile else "Select"
		select_button.disabled = slot == progress_manager.active_profile

func _on_pressed() -> void:
	status_label.text = ""
	_refresh_profiles()
	profiles_dialog.popup_centered(Vector2i(780, 440))
	opened.emit()
	profiles_dialog.get_ok_button().grab_focus()

func _on_select_pressed(slot: int) -> void:
	if confirmation.visible:
		return
	var error: Error = progress_manager.select_profile(slot)
	if error != OK:
		status_label.text = "Could not save the profile selection. Please try again."
		return
	_refresh_profiles()
	profile_changed.emit()
	profiles_dialog.hide()
	_on_closed()

func _on_delete_pressed(slot: int) -> void:
	profile_to_delete = slot
	warning_label.text = "Delete Profile %d?\nIts act unlocks and leaderboard records will be erased.\n\nType CONFIRM to enable Delete." % slot
	confirmation_input.clear()
	error_label.hide()
	confirmation.get_ok_button().disabled = true
	confirmation.popup_centered(Vector2i(680, 400))
	confirmation_input.grab_focus()

func _on_text_changed(value: String) -> void:
	confirmation.get_ok_button().disabled = value != "CONFIRM"

func _on_text_submitted(_value: String) -> void:
	_on_confirmed()

func _on_confirmed() -> void:
	if not confirmation.visible or confirmation_input.text != "CONFIRM":
		return
	var error: Error = progress_manager.delete_profile(profile_to_delete)
	if error != OK:
		error_label.text = "Could not save the deletion. Your profile was kept."
		error_label.show()
		return
	confirmation.hide()
	status_label.text = "Profile %d deleted." % profile_to_delete
	_refresh_profiles()
	profile_changed.emit()
	slots.get_node("Delete%d" % profile_to_delete).call_deferred("grab_focus")

func _on_delete_canceled() -> void:
	slots.get_node("Delete%d" % profile_to_delete).call_deferred("grab_focus")

func _on_closed() -> void:
	closed.emit()
	call_deferred("grab_focus")

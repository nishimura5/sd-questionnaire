extends SceneTree

const FIXTURE_PATH := "res://tests/fixtures/questionnaire_subdirectory.json"

var _failures: Array[String] = []


func _init() -> void:
	_test_loader_and_csv_id()
	_test_subdirectory_disabled_configs()
	_test_respondent_id_panel()

	if _failures.is_empty():
		print("questionnaire_subdirectory_test: PASS")
		quit()
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_loader_and_csv_id() -> void:
	var spec := QuestionnaireLoader.load_from_file(FIXTURE_PATH)
	_expect(spec != null, "QuestionnaireLoader should load the subdirectory fixture.")
	if spec == null:
		return

	_expect(spec.requires_stimulus_subdirectory_selection(), "A subdirectory selection should be required.")
	_expect(spec.stimulus_subdirectories.has("kenney_car"), "kenney_car should be listed.")
	_expect(spec.stimulus_subdirectories.has("kaykit_adventurers_2"), "kaykit_adventurers_2 should be listed.")
	_expect(spec.stimuli.is_empty(), "GLBs should not be added before a subdirectory is selected.")

	var selected := QuestionnaireLoader.select_stimulus_subdirectory(spec, "kenney_car")
	_expect(selected, "kenney_car should be selectable.")
	if not selected:
		return

	_expect(not spec.stimuli.is_empty(), "GLBs in kenney_car should be added.")
	var has_configured_van := false
	for stimulus in spec.stimuli:
		var file_name := str(stimulus.get("file_name", ""))
		_expect(file_name.begins_with("kenney_car/"), "Stimulus should use a root-relative subdirectory path: %s" % file_name)
		if stimulus.get("id", "") == "configured_van" and file_name == "kenney_car/van.glb":
			has_configured_van = true
	_expect(
		has_configured_van,
		"Configured stimulus paths should be relative to the selected subdirectory."
	)

	_expect(spec.get_csv_stimulus_id("sti_001") == "kenney_car/sti_001", "CSV stimulus ID should include the folder.")
	_expect(spec.get_csv_stimulus_id("kenney_car/sti_001") == "kenney_car/sti_001", "CSV folder prefix should not be duplicated.")


func _test_subdirectory_disabled_configs() -> void:
	for path in [
		"res://assets/questionnaire_car.json",
		"res://assets/questionnaire_character.json"
	]:
		var spec := QuestionnaireLoader.load_from_file(path)
		_expect(spec != null, "%s should load." % path)
		if spec == null:
			continue
		_expect(not spec.use_subdirectory, "%s should disable subdirectory selection." % path)
		_expect(not spec.requires_stimulus_subdirectory_selection(), "%s should not require a folder." % path)


func _test_respondent_id_panel() -> void:
	var panel := RespondentIdPanel.new()
	panel.setup("回答者ID", "回答者IDを入力してください。", ["folder_a", "folder_b"])
	_expect(panel.get_selected_subdirectory().is_empty(), "The folder placeholder should not count as a selection.")

	var line_edit := panel.get("_line_edit") as LineEdit
	var selector := panel.get("_folder_selector") as OptionButton
	_expect(line_edit != null, "Respondent ID input should exist.")
	_expect(selector != null, "Folder selector should exist.")
	if line_edit == null or selector == null:
		panel.free()
		return

	line_edit.text = "respondent-01"
	selector.select(2)

	var submitted := {}
	panel.submitted.connect(
		func(respondent_id: String, selected_subdirectory: String) -> void:
			submitted["respondent_id"] = respondent_id
			submitted["selected_subdirectory"] = selected_subdirectory
	)
	panel.call("_on_submit_pressed")

	_expect(submitted.get("respondent_id", "") == "respondent-01", "The submitted respondent ID should match.")
	_expect(submitted.get("selected_subdirectory", "") == "folder_b", "The submitted folder should match.")
	panel.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

extends Node3D

const QUESTIONNAIRE_JSON_PATH := "res://assets/questionnaire_desktop.json"
const USE_GLB_FILE_NAME_AS_STIMULUS_ID_OPTION := "use_glb_file_name_as_stimulus_id"

@onready var _model_root: Node3D = $ModelRoot
@onready var _questionnaire_screen_dialog: QuestionnaireScreenDialog = $QuestionnaireScreenDialog
@onready var _respondent_id_screen_dialog: RespondentIdScreenDialog = $RespondentIdScreenDialog

@export var auto_orbit_enabled: bool = true
@export_range(0.0, 2.0, 0.01, "or_greater") var orbit_speed_rad: float = 0.25

var _spec: QuestionnaireSpec
var _current_model: Node3D
var _stimulus_order: Array[int] = []
var _current_index: int = 0
var _answers: Array[Dictionary] = []
var _respondent_id: String = ""
var _answer_start_datetime: String = ""
var _orbit_angle: float = 0.0
var _use_glb_file_name_as_stimulus_id: bool = false


func _ready() -> void:
	randomize()

	if not _load_questionnaire():
		return

	_stimulus_order = _spec.build_stimulus_order()
	_respondent_id_screen_dialog.submitted.connect(_on_respondent_id_submitted)
	_respondent_id_screen_dialog.popup()


func _process(delta: float) -> void:
	if not auto_orbit_enabled:
		return
	if _current_model == null or not is_instance_valid(_current_model):
		return

	_orbit_angle += orbit_speed_rad * delta
	_current_model.rotation.y = _orbit_angle


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			get_tree().quit()


func _load_questionnaire() -> bool:
	_spec = QuestionnaireLoader.load_from_file(QUESTIONNAIRE_JSON_PATH)
	if _spec == null:
		push_error("Failed to load questionnaire JSON: %s" % QUESTIONNAIRE_JSON_PATH)
		return false

	_load_desktop_options()
	_questionnaire_screen_dialog.setup(_spec, "SD Questionnaire")
	_questionnaire_screen_dialog.submitted.connect(_on_questionnaire_submitted)
	return true


func _load_desktop_options() -> void:
	_use_glb_file_name_as_stimulus_id = false

	var file := FileAccess.open(QUESTIONNAIRE_JSON_PATH, FileAccess.READ)
	if file == null:
		return

	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return

	if not data.has(USE_GLB_FILE_NAME_AS_STIMULUS_ID_OPTION):
		return

	if typeof(data[USE_GLB_FILE_NAME_AS_STIMULUS_ID_OPTION]) != TYPE_BOOL:
		push_warning("%s must be bool." % USE_GLB_FILE_NAME_AS_STIMULUS_ID_OPTION)
		return

	_use_glb_file_name_as_stimulus_id = bool(data[USE_GLB_FILE_NAME_AS_STIMULUS_ID_OPTION])


func _show_stimulus(index: int) -> void:
	if _current_model != null and is_instance_valid(_current_model):
		_current_model.queue_free()
		_current_model = null

	var stimulus: Dictionary = _spec.stimuli[_stimulus_order[index]]
	var file_name := str(stimulus.get("file_name", "")).strip_edges()
	var scene_path := StimulusModelLoader.resolve_path(file_name, _spec.stimulus_root_dir)
	var instance := StimulusModelLoader.instantiate(file_name, _spec.stimulus_root_dir)

	if instance is Node3D:
		_current_model = instance as Node3D
		_model_root.add_child(_current_model)
		_orbit_angle = 0.0
	else:
		if instance != null:
			instance.queue_free()
		push_warning("Failed to load stimulus: %s" % scene_path)


func _open_questionnaire(index: int) -> void:
	var stimulus: Dictionary = _spec.stimuli[_stimulus_order[index]]
	var stimulus_id := _get_stimulus_id(stimulus)
	var stimulus_description := str(stimulus.get("description", ""))
	_questionnaire_screen_dialog.reset_answers()
	_questionnaire_screen_dialog.popup_for_stimulus(
		stimulus_id,
		stimulus_description,
		index + 1,
		_stimulus_order.size()
	)


func _get_stimulus_id(stimulus: Dictionary) -> String:
	if _use_glb_file_name_as_stimulus_id:
		var file_name := str(stimulus.get("file_name", "")).strip_edges()
		var glb_file_name := file_name.get_file()
		if not glb_file_name.is_empty():
			return glb_file_name

	return str(stimulus.get("id", ""))


func _on_respondent_id_submitted(respondent_id: String) -> void:
	_respondent_id = respondent_id
	_answer_start_datetime = _get_current_datetime()
	_current_index = 0
	_answers.clear()
	_show_stimulus(_current_index)
	_open_questionnaire(_current_index)


func _on_questionnaire_submitted(stimulus_id: String, answers: Dictionary) -> void:
	_answers.append({
		"stimulus_id": stimulus_id,
		"answers": answers
	})

	_current_index += 1
	if _current_index >= _stimulus_order.size():
		_export_csv()
		return

	_show_stimulus(_current_index)
	_open_questionnaire(_current_index)


func _export_csv() -> void:
	var writer := AnswerWriter.new()
	if not writer.open(_spec.csv_file_name, _spec):
		push_error("Failed to open CSV output.")
		return

	var file_save_datetime := _get_current_datetime()
	for i in range(_answers.size()):
		var entry := _answers[i]
		writer.append_answer(
			str(i + 1),
			_respondent_id,
			_answer_start_datetime,
			file_save_datetime,
			entry["stimulus_id"],
			entry["answers"]
		)

	print("CSV exported: %s" % ProjectSettings.globalize_path(writer.output_path))


func _get_current_datetime() -> String:
	return Time.get_datetime_string_from_system().replace(":", "-")

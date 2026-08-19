extends Node3D

const QUESTIONNAIRE_JSON_PATH := "res://assets/questionnaire_desktop.json"
const THUMBNAIL_SIZE := Vector2i(600, 600)
const THUMBNAIL_DIRECTORY_NAME := "thumb"
const USE_GLB_FILE_NAME_AS_STIMULUS_ID_OPTION := "use_glb_file_name_as_stimulus_id"

@onready var _thumbnail_viewport: SubViewport = $ThumbnailViewport
@onready var _camera_adjustment_dummy: MeshInstance3D = $CameraAdjustmentDummy
@onready var _model_root: Node3D = $ThumbnailViewport/ModelRoot
@onready var _subdirectory_selection: CanvasLayer = $SubdirectorySelection
@onready var _subdirectory_selector: OptionButton = %SubdirectorySelector
@onready var _generate_button: Button = %GenerateButton

var _spec: QuestionnaireSpec
var _current_model: Node3D
var _use_glb_file_name_as_stimulus_id: bool = false
var _generation_started: bool = false


func _ready() -> void:
	_thumbnail_viewport.size = THUMBNAIL_SIZE
	_camera_adjustment_dummy.hide()
	_subdirectory_selection.hide()
	_generate_button.pressed.connect(_on_generate_button_pressed)

	if not _load_questionnaire():
		get_tree().quit(1)
		return

	if _spec.requires_stimulus_subdirectory_selection():
		_show_subdirectory_selection()
		return

	_generate_thumbnails()


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

	_use_glb_file_name_as_stimulus_id = bool(
		data[USE_GLB_FILE_NAME_AS_STIMULUS_ID_OPTION]
	)


func _show_subdirectory_selection() -> void:
	_subdirectory_selector.clear()
	for subdirectory in _spec.stimulus_subdirectories:
		_subdirectory_selector.add_item(subdirectory)

	_generate_button.disabled = _subdirectory_selector.item_count == 0
	_subdirectory_selection.show()


func _on_generate_button_pressed() -> void:
	if _generation_started or _subdirectory_selector.selected < 0:
		return

	var selected_subdirectory := _subdirectory_selector.get_item_text(
		_subdirectory_selector.selected
	)
	if not QuestionnaireLoader.select_stimulus_subdirectory(_spec, selected_subdirectory):
		push_error("Failed to load GLB files from: %s" % selected_subdirectory)
		return

	_subdirectory_selection.hide()
	_generate_thumbnails()


func _generate_thumbnails() -> void:
	if _generation_started:
		return
	_generation_started = true

	if _spec.stimuli.is_empty():
		push_error("No stimuli were loaded.")
		get_tree().quit(1)
		return

	var output_directory := _prepare_output_directory()
	if output_directory.is_empty():
		get_tree().quit(1)
		return

	var saved_count := 0
	var failed_count := 0
	var used_file_stems := {}

	for stimulus_value in _spec.stimuli:
		var stimulus: Dictionary = stimulus_value
		var stimulus_id := _get_stimulus_id(stimulus)
		var file_stem := _get_thumbnail_file_stem(stimulus_id)
		if not _is_valid_thumbnail_file_stem(file_stem):
			failed_count += 1
			continue
		if used_file_stems.has(file_stem):
			push_warning("Duplicate thumbnail file name; skipped: %s.png" % file_stem)
			failed_count += 1
			continue
		used_file_stems[file_stem] = true

		if not _show_stimulus(stimulus):
			failed_count += 1
			continue

		# Wait until the newly loaded model has been drawn by the SubViewport.
		await get_tree().process_frame
		RenderingServer.force_draw(false)

		var output_path := output_directory.path_join("%s.png" % file_stem)
		if not _save_thumbnail(output_path):
			failed_count += 1
		else:
			saved_count += 1
			print("Thumbnail saved: %s" % output_path)

		_free_current_model()

	print(
		"Thumbnail generation finished: %d saved, %d failed (%s)" %
		[saved_count, failed_count, output_directory]
	)
	get_tree().quit(0 if failed_count == 0 else 1)


func _show_stimulus(stimulus: Dictionary) -> bool:
	_free_current_model()

	var file_name := str(stimulus.get("file_name", "")).strip_edges()
	var scene_path := StimulusModelLoader.resolve_path(file_name, _spec.stimulus_root_dir)
	var instance := StimulusModelLoader.instantiate(file_name, _spec.stimulus_root_dir)
	if instance is Node3D:
		_current_model = instance as Node3D
		_model_root.add_child(_current_model)
		return true

	if instance != null:
		instance.free()
	push_warning("Failed to load stimulus: %s" % scene_path)
	return false


func _save_thumbnail(output_path: String) -> bool:
	var image: Image = _thumbnail_viewport.get_texture().get_image()
	if image == null or image.is_empty():
		push_warning("Failed to read the rendered thumbnail: %s" % output_path)
		return false
	if image.get_size() != THUMBNAIL_SIZE:
		push_warning(
			"Unexpected thumbnail size %s: %s" % [image.get_size(), output_path]
		)
		return false

	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_warning(
			"Failed to save thumbnail: %s (%s)" %
			[output_path, error_string(save_error)]
		)
		return false

	return true


func _free_current_model() -> void:
	if _current_model == null or not is_instance_valid(_current_model):
		_current_model = null
		return

	_current_model.free()
	_current_model = null


func _get_stimulus_id(stimulus: Dictionary) -> String:
	if _use_glb_file_name_as_stimulus_id:
		var file_name := str(stimulus.get("file_name", "")).strip_edges()
		var glb_file_name := file_name.get_file()
		if not glb_file_name.is_empty():
			return glb_file_name

	return str(stimulus.get("id", "")).strip_edges()


func _get_thumbnail_file_stem(stimulus_id: String) -> String:
	if stimulus_id.get_extension().to_lower() == "glb":
		return stimulus_id.get_basename()
	return stimulus_id


func _is_valid_thumbnail_file_stem(file_stem: String) -> bool:
	if file_stem.is_empty():
		push_warning("Empty thumbnail file name; skipped.")
		return false
	if file_stem != file_stem.get_file() or file_stem == "." or file_stem == "..":
		push_warning("stimulus_id cannot be used as a file name: %s" % file_stem)
		return false
	return true


func _prepare_output_directory() -> String:
	var configured := _spec.csv_output_directory.strip_edges()
	if configured.is_empty():
		configured = "Desktop"

	var directory_name := configured.trim_prefix("~/")
	var system_dir_id: int
	match directory_name:
		"Desktop":
			system_dir_id = OS.SYSTEM_DIR_DESKTOP
		"Downloads":
			system_dir_id = OS.SYSTEM_DIR_DOWNLOADS
		"Documents":
			system_dir_id = OS.SYSTEM_DIR_DOCUMENTS
		_:
			push_error(
				"csv_output_directory must be Desktop, Downloads, or Documents: %s" %
				configured
			)
			return ""

	var base_directory := OS.get_system_dir(system_dir_id)
	if base_directory.is_empty():
		push_error("Failed to resolve csv_output_directory: %s" % configured)
		return ""

	var output_directory := base_directory.path_join(THUMBNAIL_DIRECTORY_NAME)
	var make_directory_error := DirAccess.make_dir_recursive_absolute(output_directory)
	if make_directory_error != OK:
		push_error(
			"Failed to create thumbnail directory: %s (%s)" %
			[output_directory, error_string(make_directory_error)]
		)
		return ""

	return output_directory

# res://sd_questionnaire/questionnaire_spec.gd
class_name QuestionnaireSpec
extends RefCounted

var stimuli: Array = []
var configured_stimuli: Array = []
var stimulus_root_dir: String = "res://assets"
var load_all_glbs: bool = false
var use_subdirectory: bool = false
var stimulus_subdirectories: Array[String] = []
var selected_stimulus_subdirectory: String = ""
var points: int = 7
var adjective_pairs: Array = []
var randomise_stimuli: bool = false
var randomise_adjective_pairs: bool = false
var csv_file_name: String = "sd_answers.csv"
var csv_output_directory: String = ""
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()

func get_pair_ids() -> Array[String]:
	var ids: Array[String] = []

	for pair in adjective_pairs:
		ids.append(str(pair.get("id", "")))

	return ids


func requires_stimulus_subdirectory_selection() -> bool:
	return (
		use_subdirectory
		and load_all_glbs
		and not stimulus_subdirectories.is_empty()
		and selected_stimulus_subdirectory.is_empty()
	)


func get_csv_stimulus_id(stimulus_id: String) -> String:
	var normalized_subdirectory := selected_stimulus_subdirectory.replace("\\", "/").strip_edges().trim_suffix("/")
	var normalized_stimulus_id := stimulus_id.replace("\\", "/").strip_edges().trim_prefix("/")
	if normalized_subdirectory.is_empty() or normalized_stimulus_id.is_empty():
		return normalized_stimulus_id
	if normalized_stimulus_id == normalized_subdirectory or normalized_stimulus_id.begins_with("%s/" % normalized_subdirectory):
		return normalized_stimulus_id
	return normalized_subdirectory.path_join(normalized_stimulus_id)


func build_stimulus_order() -> Array[int]:
	var order: Array[int] = []

	for i in stimuli.size():
		order.append(i)

	if randomise_stimuli:
		_shuffle_indices(order)

	return order


func build_adjective_pair_order() -> Array[int]:
	var order: Array[int] = []

	for i in adjective_pairs.size():
		order.append(i)

	if randomise_adjective_pairs:
		_shuffle_indices(order)

	return order


func _shuffle_indices(indices: Array[int]) -> void:
	if indices.size() < 2:
		return

	for i in range(indices.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, i)
		var current := indices[i]
		indices[i] = indices[swap_index]
		indices[swap_index] = current

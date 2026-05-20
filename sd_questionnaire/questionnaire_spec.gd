# res://sd_questionnaire/questionnaire_spec.gd
class_name QuestionnaireSpec
extends RefCounted

var stimuli: Array = []
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

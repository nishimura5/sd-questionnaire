# res://sd_questionnaire/questionnaire_loader.gd
class_name QuestionnaireLoader
extends RefCounted

static func load_from_file(path: String) -> QuestionnaireSpec:
	if not FileAccess.file_exists(path):
		push_error("JSON が見つかりません: %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("JSON を開けません: %s" % path)
		return null

	var text := file.get_as_text()
	var data = JSON.parse_string(text)

	if typeof(data) != TYPE_DICTIONARY:
		push_error("JSON の形式が不正です。root は object にしてください。")
		return null

	var spec := QuestionnaireSpec.new()

	if not _parse_points(data, spec):
		return null

	if not _parse_stimuli(data, spec, path):
		return null

	if not _parse_adjective_pairs(data, spec):
		return null

	_parse_randomise(data, spec)
	_parse_csv_file_name(data, spec)
	_parse_csv_output_directory(data, spec)

	return spec


static func _parse_points(data: Dictionary, spec: QuestionnaireSpec) -> bool:
	if not data.has("points"):
		push_error("points は必須です。5 または 7 を指定してください。")
		return false

	spec.points = int(data["points"])
	if spec.points != 5 and spec.points != 7:
		push_error("points は 5 または 7 のみ対応します。")
		return false

	return true


static func _parse_stimuli(data: Dictionary, spec: QuestionnaireSpec, json_path: String) -> bool:
	if data.has("load_all_glbs") and typeof(data["load_all_glbs"]) != TYPE_BOOL:
		push_error("load_all_glbs は bool で定義してください。")
		return false

	var load_all_glbs := bool(data.get("load_all_glbs", false))
	var stimuli_data: Array = []

	if data.has("stimuli"):
		if typeof(data["stimuli"]) != TYPE_ARRAY:
			push_error("stimuli は array で定義してください。")
			return false
		stimuli_data = data["stimuli"]
	elif not load_all_glbs:
		push_error("stimuli は array で定義してください。")
		return false

	var stimulus_ids := {}
	var stimulus_files := {}

	for stimulus in stimuli_data:
		if typeof(stimulus) != TYPE_DICTIONARY:
			push_error("stimuli の各要素は object にしてください。")
			return false

		var file_name := str(stimulus.get("file_name", "")).strip_edges()
		if file_name.is_empty():
			push_error("stimuli の各要素には file_name が必要です。")
			return false

		var description := str(stimulus.get("description", "")).strip_edges()
		var stimulus_id := str(stimulus.get("id", "")).strip_edges()
		if stimulus_id.is_empty():
			stimulus_id = file_name.get_file().get_basename()

		if stimulus_ids.has(stimulus_id):
			push_error("Duplicated id. Check json")
			return false

		stimulus_ids[stimulus_id] = true
		stimulus_files[_stimulus_file_key(file_name)] = true
		spec.stimuli.append(
			{
				"id": stimulus_id,
				"description": description,
				"file_name": file_name
			}
		)

	if load_all_glbs and not _append_directory_glbs(json_path, spec, stimulus_ids, stimulus_files):
		return false

	if spec.stimuli.is_empty():
		push_error("stimuli が空です。1件以上定義してください。")
		return false

	return true


static func _stimulus_file_key(file_name: String) -> String:
	return file_name.replace("\\", "/").trim_prefix("./").to_lower()


static func _append_directory_glbs(
	json_path: String,
	spec: QuestionnaireSpec,
	stimulus_ids: Dictionary,
	stimulus_files: Dictionary
) -> bool:
	var directory_path := json_path.get_base_dir()
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("GLB フォルダを開けません: %s" % directory_path)
		return false

	var glb_files: Array[String] = []
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.get_extension().to_lower() == "glb":
			glb_files.append(file_name)
		file_name = directory.get_next()
	directory.list_dir_end()

	glb_files.sort()

	var generated_index := 1
	for glb_file_name in glb_files:
		if stimulus_files.has(_stimulus_file_key(glb_file_name)):
			continue

		var stimulus_id := "sti_%03d" % generated_index
		generated_index += 1
		if stimulus_ids.has(stimulus_id):
			push_error("Duplicated id. Check json")
			return false

		stimulus_ids[stimulus_id] = true
		spec.stimuli.append(
			{
				"id": stimulus_id,
				"description": "",
				"file_name": glb_file_name
			}
		)

	return true


static func _parse_adjective_pairs(data: Dictionary, spec: QuestionnaireSpec) -> bool:
	if not data.has("adjective_pairs") or typeof(data["adjective_pairs"]) != TYPE_ARRAY:
		push_error("adjective_pairs は array で定義してください。")
		return false

	var pair_ids := {}

	for pair in data["adjective_pairs"]:
		var left := ""
		var right := ""
		var pair_id := ""

		if typeof(pair) == TYPE_ARRAY:
			if pair.size() != 2:
				push_error("adjective_pairs の配列要素は [left, right] の2要素にしてください。")
				return false
			left = str(pair[0]).strip_edges()
			right = str(pair[1]).strip_edges()
		elif typeof(pair) == TYPE_DICTIONARY:
			left = str(pair.get("left", "")).strip_edges()
			right = str(pair.get("right", "")).strip_edges()
			pair_id = str(pair.get("id", "")).strip_edges()
		else:
			push_error("adjective_pairs の各要素は [left, right] または object にしてください。")
			return false

		if left.is_empty() or right.is_empty():
			push_error("adjective_pairs に空文字は使えません。")
			return false

		if pair_id.is_empty():
			pair_id = "%s-%s" % [left, right]

		if pair_ids.has(pair_id):
			push_error("adjective_pairs の id が重複しています: %s" % pair_id)
			return false

		pair_ids[pair_id] = true
		spec.adjective_pairs.append({"id": pair_id, "left": left, "right": right})

	if spec.adjective_pairs.is_empty():
		push_error("adjective_pairs が空です。1件以上定義してください。")
		return false

	return true


static func _parse_randomise(data: Dictionary, spec: QuestionnaireSpec) -> void:
	if not data.has("randomise"):
		return

	var randomise = data["randomise"]
	if typeof(randomise) == TYPE_DICTIONARY:
		spec.randomise_stimuli = bool(randomise.get("stimuli", false))
		spec.randomise_adjective_pairs = bool(randomise.get("adjective_pairs", false))
		return

	push_warning("randomise は {stimuli, adjective_pairs} object を使用してください。")


static func _parse_csv_file_name(data: Dictionary, spec: QuestionnaireSpec) -> void:
	if not data.has("csv_file_name"):
		return

	var csv_file_name := str(data["csv_file_name"]).strip_edges()
	if csv_file_name.is_empty():
		push_warning("csv_file_name が空です。既定値 sd_answers.csv を使用します。")
		return

	spec.csv_file_name = csv_file_name


static func _parse_csv_output_directory(data: Dictionary, spec: QuestionnaireSpec) -> void:
	if not data.has("csv_output_directory"):
		return

	var csv_output_directory := str(data["csv_output_directory"]).strip_edges()
	if csv_output_directory.is_empty():
		return

	var normalized := csv_output_directory.trim_prefix("~/")
	match normalized:
		"Desktop", "Downloads", "Documents":
			spec.csv_output_directory = normalized
		_:
			push_error("csv_output_directory は Desktop, Downloads, Documents のいずれかを指定してください。")

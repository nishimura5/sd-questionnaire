# res://sd_questionnaire/answer_writer.gd
class_name AnswerWriter
extends RefCounted

var output_path: String = ""
var spec: QuestionnaireSpec


func open(p_output_name: String, p_spec: QuestionnaireSpec) -> bool:
	spec = p_spec
	output_path = _resolve_output_path(p_output_name)
	if output_path.is_empty():
		return false

	var should_write_header := true

	if FileAccess.file_exists(output_path):
		var existing := FileAccess.open(output_path, FileAccess.READ)
		if existing != null and existing.get_length() > 0:
			should_write_header = false

	if should_write_header:
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			push_error("CSVファイルを作成できません: %s" % output_path)
			return false

		file.store_line(_to_csv_line(_make_header()))

	return true


func append_answer(
	row_id: String,
	respondent_id: String,
	answer_start_datetime: String,
	file_save_datetime: String,
	stimulus_id: String,
	answers: Dictionary
) -> bool:
	if output_path.is_empty() or spec == null:
		push_error("AnswerWriter.open() が呼ばれていません。")
		return false

	var file := FileAccess.open(output_path, FileAccess.READ_WRITE)
	if file == null:
		push_error("CSVファイルを開けません: %s" % output_path)
		return false

	file.seek_end()

	var row: Array[String] = [
		row_id,
		respondent_id,
		answer_start_datetime,
		file_save_datetime,
		spec.get_csv_stimulus_id(stimulus_id)
	]

	for pair_id in spec.get_pair_ids():
		row.append(str(answers.get(pair_id, "")))

	file.store_line(_to_csv_line(row))
	return true


func _resolve_output_path(p_output_name: String) -> String:
	if spec == null:
		push_error("AnswerWriter.open() の spec が未設定です。")
		return ""

	var output_name := p_output_name.strip_edges()
	if output_name.is_empty():
		push_error("CSV の出力ファイル名が空です。")
		return ""

	var directory := _resolve_output_directory()
	if directory.is_empty():
		return ""

	DirAccess.make_dir_recursive_absolute(directory)
	return directory.path_join(output_name)


func _resolve_output_directory() -> String:
	var configured := spec.csv_output_directory.strip_edges()
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
			push_warning("csv_output_directory は Desktop, Downloads, Documents のいずれかを指定してください。Desktop を使用します。")
			system_dir_id = OS.SYSTEM_DIR_DESKTOP

	var output_directory := OS.get_system_dir(system_dir_id)
	if output_directory.is_empty():
		push_error("CSV の保存先ディレクトリを取得できませんでした。")
		return ""

	return output_directory


func _make_header() -> Array[String]:
	var header: Array[String] = [
		"id",
		"respondent_id",
		"answer_start_datetime",
		"file_save_datetime",
		"stimulus_id"
	]

	for pair_id in spec.get_pair_ids():
		header.append(pair_id)

	return header


func _to_csv_line(values: Array[String]) -> String:
	var escaped: Array[String] = []

	for value in values:
		escaped.append(_escape_csv(value))

	return ",".join(escaped)


func _escape_csv(value: String) -> String:
	var needs_quote := (
		value.contains(",")
		or value.contains("\"")
		or value.contains("\n")
		or value.contains("\r")
	)

	var escaped := value.replace("\"", "\"\"")

	if needs_quote:
		return "\"%s\"" % escaped

	return escaped

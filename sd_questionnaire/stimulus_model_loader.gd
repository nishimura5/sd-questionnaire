# res://sd_questionnaire/stimulus_model_loader.gd
class_name StimulusModelLoader
extends RefCounted

const DEFAULT_ROOT_DIR := "res://assets"


static func instantiate(file_name: String, root_dir: String = "") -> Node:
	var full_path := resolve_path(file_name, root_dir)
	if full_path.is_empty():
		return null

	if _is_project_path(full_path):
		var resource = load(full_path)
		if resource is PackedScene:
			return (resource as PackedScene).instantiate()

	var extension := full_path.get_extension().to_lower()
	if extension != "glb" and extension != "gltf":
		push_warning("未対応の刺激ファイル形式です: %s" % full_path)
		return null

	if not FileAccess.file_exists(full_path):
		push_warning("刺激ファイルが見つかりません: %s" % full_path)
		return null

	var gltf_document := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	var error := gltf_document.append_from_file(full_path, gltf_state)
	if error != OK:
		push_warning("GLBを読み込めません: %s (%s)" % [full_path, error_string(error)])
		return null

	return gltf_document.generate_scene(gltf_state)


static func resolve_path(file_name: String, root_dir: String = "") -> String:
	var stimulus_path := file_name.strip_edges().replace("\\", "/")
	if stimulus_path.is_empty():
		push_warning("stimuli.file_name が空です。")
		return ""

	if _is_project_path(stimulus_path) or _is_absolute_path(stimulus_path):
		return stimulus_path

	var base_dir := root_dir.strip_edges().replace("\\", "/")
	if base_dir.is_empty():
		base_dir = DEFAULT_ROOT_DIR

	return base_dir.trim_suffix("/").path_join(stimulus_path.trim_prefix("./"))


static func _is_project_path(path: String) -> bool:
	return path.begins_with("res://") or path.begins_with("user://")


static func _is_absolute_path(path: String) -> bool:
	return path.begins_with("/") or path.find(":") == 1

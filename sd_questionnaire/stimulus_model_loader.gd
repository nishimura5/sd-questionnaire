# res://sd_questionnaire/stimulus_model_loader.gd
class_name StimulusModelLoader
extends RefCounted

const DEFAULT_ROOT_DIR := "res://assets"


static func instantiate(file_name: String, root_dir: String = "") -> Node:
	var full_path := resolve_path(file_name, root_dir)
	if full_path.is_empty():
		return null

	var extension := full_path.get_extension().to_lower()
	if _is_project_path(full_path):
		var resource = load(full_path)
		if resource is PackedScene:
			var packed_scene_instance := (resource as PackedScene).instantiate()
			if _is_gltf_extension(extension):
				_log_gltf_details(full_path, packed_scene_instance)
			return packed_scene_instance

	if not _is_gltf_extension(extension):
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

	var scene := gltf_document.generate_scene(gltf_state)
	if scene != null:
		_log_gltf_details(full_path, scene)
	return scene


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


static func _is_gltf_extension(extension: String) -> bool:
	return extension == "glb" or extension == "gltf"


static func _log_gltf_details(path: String, scene: Node) -> void:
	var details := {
		"triangle_count": 0,
		"has_aabb": false,
		"aabb": AABB()
	}
	_collect_model_details(scene, Transform3D.IDENTITY, details)

	var size := Vector3.ZERO
	if bool(details["has_aabb"]):
		var aabb: AABB = details["aabb"]
		size = aabb.size

	print(
		"GLB loaded:,%s,%d,%.4f,%.4f,%.4f" %
		[
			path.get_file(),
			int(details["triangle_count"]),
			size.x,
			size.y,
			size.z
		]
	)


static func _collect_model_details(node: Node, parent_transform: Transform3D, details: Dictionary) -> void:
	var node_transform := parent_transform
	if node is Node3D:
		node_transform = parent_transform * (node as Node3D).transform

	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			details["triangle_count"] = int(details["triangle_count"]) + _count_mesh_triangles(mesh_instance.mesh)
			var mesh_aabb := _transform_aabb(mesh_instance.mesh.get_aabb(), node_transform)
			if bool(details["has_aabb"]):
				var current_aabb: AABB = details["aabb"]
				details["aabb"] = current_aabb.merge(mesh_aabb)
			else:
				details["aabb"] = mesh_aabb
				details["has_aabb"] = true

	for child in node.get_children():
		_collect_model_details(child, node_transform, details)


static func _count_mesh_triangles(mesh: Mesh) -> int:
	if mesh is ArrayMesh:
		return _count_array_mesh_triangles(mesh as ArrayMesh)

	return int(mesh.get_faces().size() / 3)


static func _count_array_mesh_triangles(mesh: ArrayMesh) -> int:
	var triangle_count := 0
	for surface_index in range(mesh.get_surface_count()):
		var primitive_type := mesh.surface_get_primitive_type(surface_index)
		if primitive_type != Mesh.PRIMITIVE_TRIANGLES and primitive_type != Mesh.PRIMITIVE_TRIANGLE_STRIP:
			continue

		var vertex_count := mesh.surface_get_array_len(surface_index)
		var index_count := mesh.surface_get_array_index_len(surface_index)
		var element_count := index_count if index_count > 0 else vertex_count
		if primitive_type == Mesh.PRIMITIVE_TRIANGLES:
			triangle_count += int(element_count / 3)
		else:
			triangle_count += maxi(0, element_count - 2)

	return triangle_count


static func _transform_aabb(aabb: AABB, transform: Transform3D) -> AABB:
	var min_point := transform * aabb.position
	var max_point := min_point
	for point in _get_aabb_corners(aabb):
		var transformed_point := transform * point
		min_point = min_point.min(transformed_point)
		max_point = max_point.max(transformed_point)

	return AABB(min_point, max_point - min_point)


static func _get_aabb_corners(aabb: AABB) -> Array[Vector3]:
	var position := aabb.position
	var end := aabb.end
	return [
		Vector3(position.x, position.y, position.z),
		Vector3(end.x, position.y, position.z),
		Vector3(position.x, end.y, position.z),
		Vector3(position.x, position.y, end.z),
		Vector3(end.x, end.y, position.z),
		Vector3(end.x, position.y, end.z),
		Vector3(position.x, end.y, end.z),
		Vector3(end.x, end.y, end.z)
	]

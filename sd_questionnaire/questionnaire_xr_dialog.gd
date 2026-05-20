class_name QuestionnaireXrDialog
extends Node3D

signal submitted(stimulus_id: String, answers: Dictionary)

const DEFAULT_PANEL_SCENE := preload("res://sd_questionnaire/questionnaire_panel.tscn")

@export var panel_scene: PackedScene
@export var viewport_size := Vector2i(1024, 512)
@export var quad_size_m := Vector2(1.35, 0.68)
@export var distance_from_camera_m: float = 1.35
@export var vertical_offset_from_camera_m: float = -0.42
@export var prefer_openxr_composition_layer: bool = true
@export var use_unshaded_fallback_quad: bool = true
@export var fallback_quad_visible_when_composition_layer_exists: bool = false
@export var follow_camera_while_visible: bool = true

var _camera: Camera3D
var _viewport: SubViewport
var _panel: QuestionnairePanel
var _composition_layer: Node3D
var _fallback_quad: MeshInstance3D
var _pointer_pressed := false
var _last_pointer_position := Vector2.ZERO


func _ready() -> void:
	_ensure_nodes()
	_update_visibility(false)
	set_process(true)


func setup(spec: QuestionnaireSpec, p_title: String = "SD Questionnaire") -> void:
	_ensure_nodes()
	_panel.setup(spec, p_title)
	_update_viewport_layout()


func set_follow_camera(camera: Camera3D) -> void:
	_camera = camera
	_update_pose()


func popup_for_stimulus(stimulus_id: String, stimulus_description: String = "") -> void:
	_ensure_nodes()
	_panel.popup_for_stimulus(stimulus_id, stimulus_description)
	_update_visibility(true)
	_update_viewport_layout()
	_update_pose()


func reset_answers() -> void:
	if is_instance_valid(_panel):
		_panel.reset_answers()


func _process(_delta: float) -> void:
	if not follow_camera_while_visible:
		return
	if not visible:
		return
	_update_pose()


func _ensure_nodes() -> void:
	if is_instance_valid(_viewport):
		return

	_viewport = SubViewport.new()
	_viewport.name = "QuestionnaireViewport"
	_viewport.size = viewport_size
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	_panel = _instantiate_panel()
	_panel.name = "QuestionnairePanel"
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.position = Vector2.ZERO
	_panel.size = Vector2(viewport_size)
	_viewport.add_child(_panel)
	_panel.submitted.connect(_on_panel_submitted)

	if prefer_openxr_composition_layer and ClassDB.class_exists("OpenXRCompositionLayerQuad"):
		_composition_layer = ClassDB.instantiate("OpenXRCompositionLayerQuad") as Node3D
		if is_instance_valid(_composition_layer):
			_composition_layer.name = "QuestionnaireOpenXRCompositionLayerQuad"
			add_child(_composition_layer)
			_composition_layer.set("layer_viewport", _viewport)
			_composition_layer.set("quad_size", quad_size_m)
			_composition_layer.set("alpha_blend", true)

	if not is_instance_valid(_composition_layer) or fallback_quad_visible_when_composition_layer_exists:
		_create_fallback_quad()


func _instantiate_panel() -> QuestionnairePanel:
	var scene: PackedScene = panel_scene
	if scene == null:
		scene = DEFAULT_PANEL_SCENE

	var instance := scene.instantiate()
	if instance is QuestionnairePanel:
		return instance as QuestionnairePanel

	push_warning("panel_scene の root は QuestionnairePanel にしてください。コード生成に戻します。")
	if instance != null:
		instance.free()
	return QuestionnairePanel.new()


func _create_fallback_quad() -> void:
	if is_instance_valid(_fallback_quad):
		return

	_fallback_quad = MeshInstance3D.new()
	_fallback_quad.name = "QuestionnaireFallbackQuad"
	var mesh := QuadMesh.new()
	mesh.size = quad_size_m
	_fallback_quad.mesh = mesh
	_fallback_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var material := StandardMaterial3D.new()
	material.albedo_texture = _viewport.get_texture()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if use_unshaded_fallback_quad:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fallback_quad.material_override = material
	add_child(_fallback_quad)


func _update_viewport_layout() -> void:
	if not is_instance_valid(_viewport) or not is_instance_valid(_panel):
		return

	_viewport.size = viewport_size
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.position = Vector2.ZERO
	_panel.size = Vector2(viewport_size)

	if is_instance_valid(_composition_layer):
		_composition_layer.set("quad_size", quad_size_m)
	if is_instance_valid(_fallback_quad) and _fallback_quad.mesh is QuadMesh:
		(_fallback_quad.mesh as QuadMesh).size = quad_size_m


func _update_visibility(value: bool) -> void:
	visible = value
	if is_instance_valid(_panel):
		_panel.visible = value
	if is_instance_valid(_composition_layer):
		_composition_layer.visible = value
	if is_instance_valid(_fallback_quad):
		_fallback_quad.visible = value


func _resolve_camera() -> Camera3D:
	if is_instance_valid(_camera):
		return _camera
	var viewport := get_viewport()
	if viewport != null:
		_camera = viewport.get_camera_3d()
	return _camera


func _update_pose() -> void:
	var camera := _resolve_camera()
	if not is_instance_valid(camera):
		return

	var camera_transform := camera.global_transform
	var forward := -camera_transform.basis.z.normalized()
	var up := camera_transform.basis.y.normalized()

	global_transform = Transform3D(
		camera_transform.basis.orthonormalized(),
		camera_transform.origin + forward * distance_from_camera_m + up * vertical_offset_from_camera_m
	)


func _viewport_position_from_uv(uv: Vector2) -> Vector2:
	return Vector2(uv.x * float(viewport_size.x), uv.y * float(viewport_size.y))


func viewport_position_from_ray(ray_origin: Vector3, ray_direction: Vector3) -> Vector2:
	_ensure_nodes()

	if is_instance_valid(_composition_layer) and _composition_layer.has_method("intersects_ray"):
			var uv: Vector2 = _composition_layer.call("intersects_ray", ray_origin, ray_direction.normalized())
			if _is_valid_uv(uv):
				return _viewport_position_from_uv(uv)

	var local_origin := global_transform.affine_inverse() * ray_origin
	var local_direction := global_transform.basis.inverse() * ray_direction.normalized()
	if absf(local_direction.z) < 0.0001:
		return Vector2(-1.0, -1.0)

	var t := -local_origin.z / local_direction.z
	if t < 0.0:
		return Vector2(-1.0, -1.0)

	var local_hit := local_origin + local_direction * t
	var uv := Vector2(
		local_hit.x / quad_size_m.x + 0.5,
		0.5 - local_hit.y / quad_size_m.y
	)
	if not _is_valid_uv(uv):
		return Vector2(-1.0, -1.0)
	return _viewport_position_from_uv(uv)


func push_pointer_ray(ray_origin: Vector3, ray_direction: Vector3, pressed: bool) -> bool:
	var viewport_position := viewport_position_from_ray(ray_origin, ray_direction)
	if viewport_position.x < 0.0 or viewport_position.y < 0.0:
		if _pointer_pressed:
			_push_mouse_button(_last_pointer_position, false)
			_pointer_pressed = false
		return false

	_last_pointer_position = viewport_position
	_push_mouse_motion(viewport_position)
	if pressed != _pointer_pressed:
		_push_mouse_button(viewport_position, pressed)
		_pointer_pressed = pressed
	return true


func _push_mouse_motion(viewport_position: Vector2) -> void:
	if not is_instance_valid(_viewport):
		return
	var event := InputEventMouseMotion.new()
	event.position = viewport_position
	event.global_position = viewport_position
	_viewport.push_input(event, true)


func _push_mouse_button(viewport_position: Vector2, pressed: bool) -> void:
	if not is_instance_valid(_viewport):
		return
	var event := InputEventMouseButton.new()
	event.position = viewport_position
	event.global_position = viewport_position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	_viewport.push_input(event, true)


func _is_valid_uv(uv: Vector2) -> bool:
	return uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0


func _on_panel_submitted(stimulus_id: String, answers: Dictionary) -> void:
	_update_visibility(false)
	emit_signal("submitted", stimulus_id, answers)

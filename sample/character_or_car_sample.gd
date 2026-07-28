extends Node3D

const DEFAULT_QUESTIONNAIRE_JSON_PATH := "res://assets/questionnaire.json"
const DEFAULT_CAMERA_HEIGHT_M := 1.5
const CHARACTER_CAMERA_HEIGHT_M := 1.7
const CAR_CAMERA_HEIGHT_M := 1.07

@onready var _main_camera: Camera3D = $MainCamera
@onready var _model_root: Node3D = $ModelRoot
@onready var _questionnaire_screen_dialog: QuestionnaireScreenDialog = $QuestionnaireScreenDialog
@onready var _respondent_id_screen_dialog = $RespondentIdScreenDialog

@export_group("Questionnaire")
@export_file("*.json") var questionnaire_json_path: String = DEFAULT_QUESTIONNAIRE_JSON_PATH
@export_group("")
@export var auto_orbit_enabled: bool = true
@export_range(0.0, 2.0, 0.01, "or_greater") var orbit_speed_rad: float = 0.25

var _spec: QuestionnaireSpec
var _current_model: Node
var _stimulus_order: Array[int] = []
var _current_index: int = 0
var _collected_answers: Array = []
var _respondent_id: String = ""
var _answer_start_datetime: String = ""
var _orbit_angle: float = 0.0


func _ready() -> void:
    randomize()
    _apply_camera_height_for_questionnaire()

    if not _load_questionnaire():
        return

    _stimulus_order = _spec.build_stimulus_order()
    _current_index = 0
    _collected_answers.clear()

    _respondent_id_screen_dialog.connect("submitted", _on_respondent_id_submitted)
    _respondent_id_screen_dialog.popup()


func _process(delta: float) -> void:
    if not auto_orbit_enabled:
        return

    if _current_model == null or not is_instance_valid(_current_model):
        return

    _orbit_angle += orbit_speed_rad * delta
    _update_model_rotation()


func _update_model_rotation() -> void:
    if _current_model == null or not is_instance_valid(_current_model):
        return

    var model_node = _current_model as Node3D
    if model_node == null:
        return

    model_node.rotation.y = _orbit_angle


func _load_questionnaire() -> bool:
    _spec = QuestionnaireLoader.load_from_file(questionnaire_json_path)
    if _spec == null:
        push_error("質問紙JSONの読み込みに失敗しました。")
        return false

    _questionnaire_screen_dialog.setup(_spec, "SD法 回答")
    _questionnaire_screen_dialog.submitted.connect(_on_answers_submitted)
    return true


func _apply_camera_height_for_questionnaire() -> void:
    var camera_position := _main_camera.position
    camera_position.y = _camera_height_for_questionnaire()
    _main_camera.position = camera_position


func _camera_height_for_questionnaire() -> float:
    match questionnaire_json_path.get_file().get_basename():
        "questionnaire_character":
            return CHARACTER_CAMERA_HEIGHT_M
        "questionnaire_car":
            return CAR_CAMERA_HEIGHT_M
        _:
            return DEFAULT_CAMERA_HEIGHT_M


func _show_stimulus(index: int) -> void:
    if _spec == null or _spec.stimuli.is_empty():
        push_warning("表示する刺激がありません。")
        return

    if _current_model != null and is_instance_valid(_current_model):
        _current_model.queue_free()
        _current_model = null

    var stimulus: Dictionary = _spec.stimuli[_stimulus_order[index]]
    var file_name := str(stimulus.get("file_name", "")).strip_edges()
    if file_name.is_empty():
        push_warning("stimuli.file_name が空です。")
        return

    var full_path := StimulusModelLoader.resolve_path(file_name, _spec.stimulus_root_dir)
    var instance := StimulusModelLoader.instantiate(file_name, _spec.stimulus_root_dir)
    if instance is Node3D:
        _current_model = instance
        _model_root.add_child(_current_model)
        _prepare_model_for_cinematic_lighting(_current_model)
        _orbit_angle = 0.0
    else:
        if instance != null:
            instance.queue_free()
        push_warning("モデルを読み込めません: %s" % full_path)


func _prepare_model_for_cinematic_lighting(root: Node) -> void:
    var nodes: Array[Node] = [root]
    while not nodes.is_empty():
        var node : Node = nodes.pop_back()
        if node is GeometryInstance3D:
            var geometry := node as GeometryInstance3D
            geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
            geometry.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
            
            # 元マテリアルのアルベドテクスチャだけを残す
            if node is MeshInstance3D:
                _apply_texture_only_material(node as MeshInstance3D)

        for child in node.get_children():
            nodes.append(child)


func _apply_texture_only_material(mesh_instance: MeshInstance3D) -> void:
    if mesh_instance.mesh == null:
        return

    var surface_count := mesh_instance.mesh.get_surface_count()
    for i in range(surface_count):
        var texture := _get_surface_albedo_texture(mesh_instance, i)
        if texture == null:
            continue

        var material := StandardMaterial3D.new()
        material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
        material.albedo_texture = texture
        material.metallic = 0.0
        material.roughness = 1.0
        material.metallic_specular = 0.0
        material.clearcoat_enabled = false
        material.sheen_enabled = false
        material.anisotropy_enabled = false
        mesh_instance.set_surface_override_material(i, material)


func _get_surface_albedo_texture(mesh_instance: MeshInstance3D, surface_index: int) -> Texture2D:
    var material := mesh_instance.get_surface_override_material(surface_index)
    if material == null:
        material = mesh_instance.mesh.surface_get_material(surface_index)

    if material is BaseMaterial3D:
        return (material as BaseMaterial3D).albedo_texture

    if material is ShaderMaterial:
        var shader_material := material as ShaderMaterial
        for parameter_name in ["albedo_texture", "texture_albedo", "texture"]:
            var parameter_value = shader_material.get_shader_parameter(parameter_name)
            if parameter_value is Texture2D:
                return parameter_value as Texture2D

    return null


func _open_questionnaire_for_stimulus(index: int) -> void:
    if _spec == null or _spec.stimuli.is_empty():
        return

    var stimulus: Dictionary = _spec.stimuli[_stimulus_order[index]]
    var stimulus_id := str(stimulus.get("id", ""))
    var stimulus_description := str(stimulus.get("description", ""))
    _questionnaire_screen_dialog.reset_answers()
    _questionnaire_screen_dialog.popup_for_stimulus(
        stimulus_id,
        stimulus_description,
        index + 1,
        _stimulus_order.size()
    )


func _on_respondent_id_submitted(respondent_id: String) -> void:
    _respondent_id = respondent_id
    _answer_start_datetime = _get_current_datetime()
    _show_stimulus(_current_index)
    _open_questionnaire_for_stimulus(_current_index)


func _on_answers_submitted(stimulus_id: String, answers: Dictionary) -> void:
    _collected_answers.append({
        "stimulus_id": stimulus_id,
        "answers": answers
    })

    _current_index += 1

    if _current_index >= _stimulus_order.size():
        _export_csv()
    else:
        _show_stimulus(_current_index)
        _open_questionnaire_for_stimulus(_current_index)


func _export_csv() -> void:
    var writer := AnswerWriter.new()
    if not writer.open(_spec.csv_file_name, _spec):
        push_error("CSVファイルの初期化に失敗しました。")
        return

    var file_save_datetime := _get_current_datetime()
    for i in _collected_answers.size():
        var entry: Dictionary = _collected_answers[i]
        writer.append_answer(
            str(i + 1),
            _respondent_id,
            _answer_start_datetime,
            file_save_datetime,
            entry["stimulus_id"],
            entry["answers"]
        )

    var global_path := ProjectSettings.globalize_path(writer.output_path)
    print("CSV出力完了: %s" % global_path)


func _get_current_datetime() -> String:
    return Time.get_datetime_string_from_system().replace(":", "-")

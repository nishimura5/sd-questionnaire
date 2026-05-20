class_name QuestionnaireScreenDialog
extends CanvasLayer

signal submitted(stimulus_id: String, answers: Dictionary)

const DEFAULT_PANEL_SCENE := preload("res://sd_questionnaire/questionnaire_panel.tscn")

enum PanelPosition { BOTTOM, RIGHT }

@export var panel_scene: PackedScene
@export var panel_position: PanelPosition = PanelPosition.BOTTOM
@export var margin_px: int = 10
@export_range(0.25, 0.75, 0.05) var height_ratio: float = 0.5
@export_range(0.25, 0.75, 0.05) var width_ratio: float = 0.5
@export var layer_index: int = 100

var _panel: QuestionnairePanel
var _last_visible_rect := Rect2()


func _ready() -> void:
	layer = layer_index
	_ensure_panel()
	set_process(true)
	_update_panel_layout()


func setup(spec: QuestionnaireSpec, p_title: String = "SD Questionnaire") -> void:
	_ensure_panel()
	_panel.setup(spec, p_title)
	_update_panel_layout()


func popup_for_stimulus(stimulus_id: String, stimulus_description: String = "") -> void:
	_ensure_panel()
	_panel.popup_for_stimulus(stimulus_id, stimulus_description)
	_update_panel_layout()


func reset_answers() -> void:
	if is_instance_valid(_panel):
		_panel.reset_answers()


func _process(_delta: float) -> void:
	if not is_instance_valid(_panel):
		return
	if not _panel.visible:
		return

	var visible_rect := get_viewport().get_visible_rect()
	if visible_rect != _last_visible_rect:
		_update_panel_layout()


func _ensure_panel() -> void:
	if is_instance_valid(_panel):
		return

	_panel = _find_child_panel()
	if not is_instance_valid(_panel):
		_panel = _instantiate_panel()
		add_child(_panel)

	_panel.name = "QuestionnairePanel"
	_panel.hide()
	if not _panel.submitted.is_connected(_on_panel_submitted):
		_panel.submitted.connect(_on_panel_submitted)


func _find_child_panel() -> QuestionnairePanel:
	for child in get_children():
		if child is QuestionnairePanel:
			return child as QuestionnairePanel
	return null


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


func _update_panel_layout() -> void:
	if not is_instance_valid(_panel) or get_viewport() == null:
		return

	var visible_rect := get_viewport().get_visible_rect()
	_last_visible_rect = visible_rect
	if visible_rect.size.x <= 0.0 or visible_rect.size.y <= 0.0:
		return

	var x: int
	var y: int
	var width: int
	var height: int

	if panel_position == PanelPosition.RIGHT:
		var right_region_width := int(visible_rect.size.x * width_ratio)
		width = maxi(1, right_region_width - margin_px * 2)
		height = maxi(1, int(visible_rect.size.y) - margin_px * 2)
		x = int(visible_rect.position.x + visible_rect.size.x - float(width) - margin_px)
		y = int(visible_rect.position.y + (visible_rect.size.y - float(height)) / 2.0)
	else:
		width = maxi(1, int(visible_rect.size.x) - margin_px * 2)
		var lower_region_height := int(visible_rect.size.y * height_ratio)
		height = maxi(1, lower_region_height - margin_px * 2)
		x = int(visible_rect.position.x + (visible_rect.size.x - float(width)) / 2.0)
		y = int(visible_rect.position.y + visible_rect.size.y - float(height) - margin_px)

	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2(x, y)
	_panel.size = Vector2(width, height)


func _on_panel_submitted(stimulus_id: String, answers: Dictionary) -> void:
	emit_signal("submitted", stimulus_id, answers)

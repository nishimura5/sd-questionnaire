class_name RespondentIdScreenDialog
extends CanvasLayer

signal submitted(respondent_id: String)

const DEFAULT_PANEL_SCENE := preload("res://sd_questionnaire/respondent_id_panel.tscn")
const PANEL_SCRIPT := preload("res://sd_questionnaire/respondent_id_panel.gd")

@export var panel_scene: PackedScene
@export var panel_size_px: Vector2i = Vector2i(520, 260)
@export var margin_px: int = 16
@export var layer_index: int = 100

var _panel: Control
var _last_visible_rect := Rect2()


func _ready() -> void:
	layer = layer_index
	_ensure_panel()
	set_process(true)
	_update_panel_layout()


func setup(p_title: String = "回答者ID", p_prompt: String = "回答者IDを入力してください。") -> void:
	_ensure_panel()
	_panel.call("setup", p_title, p_prompt)
	_update_panel_layout()


func popup(initial_respondent_id: String = "") -> void:
	_ensure_panel()
	_panel.call("popup", initial_respondent_id)
	_update_panel_layout()


func hide_dialog() -> void:
	if is_instance_valid(_panel):
		_panel.hide()


func reset() -> void:
	if is_instance_valid(_panel):
		_panel.call("reset")


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

	_panel.name = "RespondentIdPanel"
	_panel.hide()
	if not _panel.is_connected("submitted", _on_panel_submitted):
		_panel.connect("submitted", _on_panel_submitted)


func _find_child_panel() -> Control:
	for child in get_children():
		if _is_panel_node(child):
			return child as Control
	return null


func _instantiate_panel() -> Control:
	var scene: PackedScene = panel_scene
	if scene == null:
		scene = DEFAULT_PANEL_SCENE

	var instance := scene.instantiate()
	if _is_panel_node(instance):
		return instance as Control

	push_warning("panel_scene の root は RespondentIdPanel にしてください。コード生成に戻します。")
	if instance != null:
		instance.free()
	return PANEL_SCRIPT.new() as Control


func _is_panel_node(node: Node) -> bool:
	return (
		node is Control
		and node.has_method("setup")
		and node.has_method("popup")
		and node.has_method("reset")
		and node.has_signal("submitted")
	)


func _update_panel_layout() -> void:
	if not is_instance_valid(_panel) or get_viewport() == null:
		return

	var visible_rect := get_viewport().get_visible_rect()
	_last_visible_rect = visible_rect
	if visible_rect.size.x <= 0.0 or visible_rect.size.y <= 0.0:
		return

	var width := mini(panel_size_px.x, maxi(1, int(visible_rect.size.x) - margin_px * 2))
	var height := mini(panel_size_px.y, maxi(1, int(visible_rect.size.y) - margin_px * 2))
	var x := int(visible_rect.position.x + (visible_rect.size.x - float(width)) / 2.0)
	var y := int(visible_rect.position.y + (visible_rect.size.y - float(height)) / 2.0)

	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2(x, y)
	_panel.size = Vector2(width, height)


func _on_panel_submitted(respondent_id: String) -> void:
	emit_signal("submitted", respondent_id)

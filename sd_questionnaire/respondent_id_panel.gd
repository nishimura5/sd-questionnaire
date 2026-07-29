class_name RespondentIdPanel
extends PanelContainer

signal submitted(respondent_id: String, selected_subdirectory: String)

@export var content_margin_px: int = 24
@export var title_text: String = "回答者ID"
@export var prompt_text: String = "回答者IDを入力してください。"
@export var placeholder_text: String = "respondent_id"
@export var folder_prompt_text: String = "フォルダ"
@export var folder_placeholder_text: String = "フォルダを選択してください。"
@export var submit_button_text: String = "次へ"
@export var title_font_size: int = 28
@export var label_font_size: int = 20
@export var input_font_size: int = 22
@export var submit_button_font_size: int = 22
@export_group("Colors")
@export var panel_background_color: Color = Color(0.08, 0.1, 0.12, 0.92):
	set(value):
		panel_background_color = value
		_update_color_theme()
@export var panel_border_color: Color = Color(0.86, 0.9, 0.94, 0.28):
	set(value):
		panel_border_color = value
		_update_color_theme()
@export var text_color: Color = Color(0.86, 0.9, 0.94):
	set(value):
		text_color = value
		_update_color_theme()
@export var muted_text_color: Color = Color(0.7, 0.76, 0.82):
	set(value):
		muted_text_color = value
		_update_color_theme()
@export var input_background_color: Color = Color(0.03, 0.04, 0.05, 0.9):
	set(value):
		input_background_color = value
		_update_color_theme()
@export var input_border_color: Color = Color(0.86, 0.9, 0.94, 0.34):
	set(value):
		input_border_color = value
		_update_color_theme()
@export var button_background_color: Color = Color(0.86, 0.9, 0.94, 0.16):
	set(value):
		button_background_color = value
		_update_color_theme()
@export var button_hover_color: Color = Color(0.86, 0.9, 0.94, 0.24):
	set(value):
		button_hover_color = value
		_update_color_theme()
@export var button_pressed_color: Color = Color(0.86, 0.9, 0.94, 0.1):
	set(value):
		button_pressed_color = value
		_update_color_theme()
@export_group("")

var _title_label: Label
var _prompt_label: Label
var _line_edit: LineEdit
var _folder_row: HBoxContainer
var _folder_label: Label
var _folder_selector: OptionButton
var _submit_button: Button
var _warning_label: Label
var _ui_built := false


func _ready() -> void:
	_ensure_ui()
	_update_submit_state()


func setup(
	p_title: String = "回答者ID",
	p_prompt: String = "回答者IDを入力してください。",
	p_subdirectories: Array[String] = []
) -> void:
	title_text = p_title
	prompt_text = p_prompt
	_ensure_ui()
	_apply_texts()
	reset()
	set_subdirectories(p_subdirectories)


func popup(initial_respondent_id: String = "") -> void:
	_ensure_ui()
	_line_edit.text = initial_respondent_id
	_warning_label.text = ""
	_update_submit_state()
	show()
	_line_edit.call_deferred("grab_focus")
	_line_edit.call_deferred("select_all")


func reset() -> void:
	if is_instance_valid(_line_edit):
		_line_edit.text = ""
	if is_instance_valid(_folder_selector) and _folder_selector.item_count > 0:
		_folder_selector.select(0)
	if is_instance_valid(_warning_label):
		_warning_label.text = ""
	_update_submit_state()


func set_subdirectories(subdirectories: Array[String]) -> void:
	_ensure_ui()
	_folder_selector.clear()

	if subdirectories.is_empty():
		_folder_row.hide()
		_update_submit_state()
		return

	_folder_selector.add_item(folder_placeholder_text)
	_folder_selector.set_item_disabled(0, true)
	for subdirectory in subdirectories:
		_folder_selector.add_item(subdirectory)
	_folder_selector.select(0)
	_folder_row.show()
	_update_submit_state()


func get_selected_subdirectory() -> String:
	if not is_instance_valid(_folder_row) or not _folder_row.visible:
		return ""
	if not is_instance_valid(_folder_selector) or _folder_selector.selected <= 0:
		return ""
	return _folder_selector.get_item_text(_folder_selector.selected)


func show_warning(message: String) -> void:
	_ensure_ui()
	_warning_label.text = message


func _ensure_ui() -> void:
	if _ui_built:
		return

	_ui_built = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", content_margin_px)
	margin.add_theme_constant_override("margin_top", content_margin_px)
	margin.add_theme_constant_override("margin_right", content_margin_px)
	margin.add_theme_constant_override("margin_bottom", content_margin_px)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", title_font_size)
	root.add_child(_title_label)

	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", label_font_size)
	root.add_child(_prompt_label)

	_line_edit = LineEdit.new()
	_line_edit.custom_minimum_size = Vector2(0, 48)
	_line_edit.add_theme_font_size_override("font_size", input_font_size)
	_line_edit.text_changed.connect(_on_id_text_changed)
	_line_edit.text_submitted.connect(_on_id_text_submitted)
	root.add_child(_line_edit)

	_folder_row = HBoxContainer.new()
	_folder_row.add_theme_constant_override("separation", 12)
	_folder_row.hide()
	root.add_child(_folder_row)

	_folder_label = Label.new()
	_folder_label.custom_minimum_size = Vector2(100, 48)
	_folder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_folder_label.add_theme_font_size_override("font_size", label_font_size)
	_folder_row.add_child(_folder_label)

	_folder_selector = OptionButton.new()
	_folder_selector.custom_minimum_size = Vector2(0, 48)
	_folder_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_folder_selector.clip_text = true
	_folder_selector.add_theme_font_size_override("font_size", input_font_size)
	_folder_selector.item_selected.connect(_on_folder_selected)
	_folder_row.add_child(_folder_selector)

	_warning_label = Label.new()
	_warning_label.text = ""
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.modulate = Color(0.9, 0.18, 0.18)
	_warning_label.add_theme_font_size_override("font_size", label_font_size)
	root.add_child(_warning_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(button_row)

	_submit_button = Button.new()
	_submit_button.disabled = true
	_submit_button.custom_minimum_size = Vector2(140, 52)
	_submit_button.add_theme_font_size_override("font_size", submit_button_font_size)
	_submit_button.pressed.connect(_on_submit_pressed)
	button_row.add_child(_submit_button)

	_apply_texts()
	_update_color_theme()


func _apply_texts() -> void:
	if is_instance_valid(_title_label):
		_title_label.text = title_text
	if is_instance_valid(_prompt_label):
		_prompt_label.text = prompt_text
	if is_instance_valid(_line_edit):
		_line_edit.placeholder_text = placeholder_text
	if is_instance_valid(_folder_label):
		_folder_label.text = folder_prompt_text
	if is_instance_valid(_submit_button):
		_submit_button.text = submit_button_text


func _update_color_theme() -> void:
	if not _ui_built:
		return

	add_theme_stylebox_override("panel", _make_panel_stylebox())

	if is_instance_valid(_title_label):
		_title_label.add_theme_color_override("font_color", text_color)
	if is_instance_valid(_prompt_label):
		_prompt_label.add_theme_color_override("font_color", muted_text_color)
	if is_instance_valid(_line_edit):
		_line_edit.add_theme_color_override("font_color", text_color)
		_line_edit.add_theme_color_override("font_placeholder_color", muted_text_color)
		_line_edit.add_theme_color_override("caret_color", text_color)
		_line_edit.add_theme_stylebox_override("normal", _make_control_stylebox(input_background_color, input_border_color, 6))
		_line_edit.add_theme_stylebox_override("focus", _make_control_stylebox(input_background_color, text_color, 6))
		_line_edit.add_theme_stylebox_override("read_only", _make_control_stylebox(input_background_color, input_border_color, 6))
	if is_instance_valid(_folder_label):
		_folder_label.add_theme_color_override("font_color", muted_text_color)
	if is_instance_valid(_folder_selector):
		_folder_selector.add_theme_color_override("font_color", text_color)
		_folder_selector.add_theme_color_override("font_hover_color", text_color)
		_folder_selector.add_theme_color_override("font_pressed_color", text_color)
		_folder_selector.add_theme_color_override("font_disabled_color", muted_text_color)
		_folder_selector.add_theme_stylebox_override("normal", _make_control_stylebox(input_background_color, input_border_color, 6))
		_folder_selector.add_theme_stylebox_override("hover", _make_control_stylebox(input_background_color, text_color, 6))
		_folder_selector.add_theme_stylebox_override("pressed", _make_control_stylebox(input_background_color, input_border_color, 6))
	if is_instance_valid(_submit_button):
		_submit_button.add_theme_color_override("font_color", text_color)
		_submit_button.add_theme_color_override("font_hover_color", text_color)
		_submit_button.add_theme_color_override("font_pressed_color", text_color)
		_submit_button.add_theme_color_override("font_disabled_color", muted_text_color)
		_submit_button.add_theme_stylebox_override("normal", _make_control_stylebox(button_background_color, input_border_color, 6))
		_submit_button.add_theme_stylebox_override("hover", _make_control_stylebox(button_hover_color, text_color, 6))
		_submit_button.add_theme_stylebox_override("pressed", _make_control_stylebox(button_pressed_color, input_border_color, 6))
		_submit_button.add_theme_stylebox_override("disabled", _make_control_stylebox(Color(0.03, 0.04, 0.05, 0.55), Color(0.86, 0.9, 0.94, 0.16), 6))


func _make_panel_stylebox() -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = panel_background_color
	stylebox.border_color = panel_border_color
	stylebox.set_border_width_all(1)
	stylebox.set_corner_radius_all(8)
	return stylebox


func _make_control_stylebox(background_color: Color, border_color: Color, corner_radius: int) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = background_color
	stylebox.border_color = border_color
	stylebox.set_border_width_all(1)
	stylebox.set_corner_radius_all(corner_radius)
	stylebox.content_margin_left = 12
	stylebox.content_margin_right = 12
	stylebox.content_margin_top = 8
	stylebox.content_margin_bottom = 8
	return stylebox


func _on_id_text_changed(_new_text: String) -> void:
	if is_instance_valid(_warning_label):
		_warning_label.text = ""
	_update_submit_state()


func _on_id_text_submitted(_new_text: String) -> void:
	if is_instance_valid(_submit_button) and not _submit_button.disabled:
		_on_submit_pressed()


func _on_folder_selected(_index: int) -> void:
	if is_instance_valid(_warning_label):
		_warning_label.text = ""
	_update_submit_state()


func _update_submit_state() -> void:
	if not is_instance_valid(_submit_button) or not is_instance_valid(_line_edit):
		return

	var folder_is_required := is_instance_valid(_folder_row) and _folder_row.visible
	var folder_is_selected := not folder_is_required or get_selected_subdirectory() != ""
	_submit_button.disabled = _line_edit.text.strip_edges().is_empty() or not folder_is_selected


func _on_submit_pressed() -> void:
	var respondent_id := _line_edit.text.strip_edges()
	if respondent_id.is_empty():
		_warning_label.text = "回答者IDを入力してください。"
		_update_submit_state()
		return
	if is_instance_valid(_folder_row) and _folder_row.visible and get_selected_subdirectory().is_empty():
		_warning_label.text = "フォルダを選択してください。"
		_update_submit_state()
		return

	hide()
	emit_signal("submitted", respondent_id, get_selected_subdirectory())

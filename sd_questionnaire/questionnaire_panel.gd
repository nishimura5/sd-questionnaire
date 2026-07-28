class_name QuestionnairePanel
extends PanelContainer

signal submitted(stimulus_id: String, answers: Dictionary)

class OptionCircleButton:
	extends Button

	var circle_radius_px: float = 20.0:
		set(value):
			circle_radius_px = value
			queue_redraw()
	var circle_stroke_width_px: float = 4.0:
		set(value):
			circle_stroke_width_px = value
			queue_redraw()
	var selected_dot_radius_px: float = 9.0:
		set(value):
			selected_dot_radius_px = value
			queue_redraw()
	var circle_fill_color: Color = Color(0.08, 0.1, 0.12):
		set(value):
			circle_fill_color = value
			queue_redraw()
	var circle_outline_color: Color = Color(0.86, 0.9, 0.94):
		set(value):
			circle_outline_color = value
			queue_redraw()
	var circle_hover_color: Color = Color(1.0, 0.78, 0.28):
		set(value):
			circle_hover_color = value
			queue_redraw()
	var circle_selected_fill_color: Color = Color(0.18, 0.52, 0.92, 0.24):
		set(value):
			circle_selected_fill_color = value
			queue_redraw()
	var circle_selected_color: Color = Color(0.18, 0.52, 0.92):
		set(value):
			circle_selected_color = value
			queue_redraw()
	var circle_focus_color: Color = Color(1.0, 0.78, 0.28, 0.9):
		set(value):
			circle_focus_color = value
			queue_redraw()

	func _init() -> void:
		text = ""
		flat = true
		toggle_mode = true
		focus_mode = Control.FOCUS_ALL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var empty_style := StyleBoxEmpty.new()
		add_theme_stylebox_override("normal", empty_style)
		add_theme_stylebox_override("hover", empty_style)
		add_theme_stylebox_override("pressed", empty_style)
		add_theme_stylebox_override("focus", empty_style)
		add_theme_stylebox_override("disabled", empty_style)

	func _ready() -> void:
		toggled.connect(_on_toggled)
		mouse_entered.connect(_queue_circle_redraw)
		mouse_exited.connect(_queue_circle_redraw)
		focus_entered.connect(_queue_circle_redraw)
		focus_exited.connect(_queue_circle_redraw)
		resized.connect(_queue_circle_redraw)

	func _draw() -> void:
		var center := size * 0.5
		var max_radius: float = minf(size.x, size.y) * 0.42
		var radius: float = minf(circle_radius_px, max_radius)
		var stroke_width: float = minf(circle_stroke_width_px, radius * 0.35)
		var outer_color := circle_outline_color

		draw_circle(center, radius + stroke_width * 0.5, circle_fill_color)

		if is_hovered() and not button_pressed:
			outer_color = circle_hover_color

		if button_pressed:
			draw_circle(center, radius, circle_selected_fill_color)
			draw_circle(center, minf(selected_dot_radius_px, radius * 0.55), circle_selected_color)
			outer_color = circle_selected_color

		draw_arc(center, radius, 0.0, TAU, 96, outer_color, stroke_width, true)

		if has_focus():
			draw_arc(center, radius + stroke_width + 3.0, 0.0, TAU, 96, circle_focus_color, 2.0, true)

	func _on_toggled(_pressed: bool) -> void:
		queue_redraw()

	func _queue_circle_redraw() -> void:
		queue_redraw()


class OptionLineContainer:
	extends HBoxContainer

	var line_enabled: bool = true:
		set(value):
			line_enabled = value
			queue_redraw()
	var line_color: Color = Color(0.86, 0.9, 0.94, 0.58):
		set(value):
			line_color = value
			queue_redraw()
	var line_width_px: float = 3.0:
		set(value):
			line_width_px = value
			queue_redraw()

	func _ready() -> void:
		resized.connect(_queue_line_redraw)
		child_order_changed.connect(_queue_line_redraw)

	func _draw() -> void:
		if not line_enabled or line_width_px <= 0.0:
			return

		var first_button := _get_edge_button(true)
		var last_button := _get_edge_button(false)
		if first_button == null or last_button == null or first_button == last_button:
			return

		var start := first_button.position + first_button.size * 0.5
		var end := last_button.position + last_button.size * 0.5
		end.y = start.y
		draw_line(start, end, line_color, line_width_px, true)

	func _get_edge_button(from_start: bool) -> Control:
		var children := get_children()
		if not from_start:
			children.reverse()

		for child in children:
			var control := child as Control
			if control != null and control.visible:
				return control

		return null

	func _queue_line_redraw() -> void:
		queue_redraw()


const DEFAULT_FONT_SIZE := 24
const DEFAULT_BUTTON_FONT_SIZE := 20
const DEFAULT_ROW_HEIGHT := 60
const DEFAULT_OPTION_BUTTON_SIZE := 68.0
const DEFAULT_OPTION_CIRCLE_RADIUS := 16.8
const DEFAULT_OPTION_CIRCLE_STROKE_WIDTH := 4.0
const DEFAULT_OPTION_SELECTED_DOT_RADIUS := 9.0
const DEFAULT_OPTION_CIRCLE_FILL_COLOR := Color(0.08, 0.1, 0.12)
const DEFAULT_OPTION_CIRCLE_OUTLINE_COLOR := Color(0.86, 0.9, 0.94)
const DEFAULT_OPTION_CIRCLE_HOVER_COLOR := Color(1.0, 0.78, 0.28)
const DEFAULT_OPTION_CIRCLE_SELECTED_FILL_COLOR := Color(0.18, 0.52, 0.92, 0.24)
const DEFAULT_OPTION_CIRCLE_SELECTED_COLOR := Color(0.18, 0.52, 0.92)
const DEFAULT_OPTION_CIRCLE_FOCUS_COLOR := Color(1.0, 0.78, 0.28, 0.9)
const DEFAULT_OPTION_LINE_ENABLED := true
const DEFAULT_OPTION_LINE_WIDTH := 3.0
const DEFAULT_OPTION_LINE_COLOR := Color(0.86, 0.9, 0.94, 0.58)
const DEFAULT_SCROLLBAR_WIDTH := 12
const DEFAULT_SCROLLBAR_CORNER_RADIUS := 6
const DEFAULT_SCROLLBAR_TRACK_COLOR := Color(0.08, 0.1, 0.12, 0.35)
const DEFAULT_SCROLLBAR_GRABBER_COLOR := Color(0.18, 0.52, 0.92)
const DEFAULT_SCROLLBAR_GRABBER_HOVER_COLOR := Color(0.28, 0.64, 1.0)
const DEFAULT_SCROLLBAR_GRABBER_PRESSED_COLOR := Color(0.12, 0.38, 0.72)

@export var content_margin_px: int = 12
@export var label_width_px: int = 180
@export var row_separation_px: int = 8
@export_group("Option Circles")
@export_range(24.0, 160.0, 1.0, "or_greater") var option_button_size_px: float = DEFAULT_OPTION_BUTTON_SIZE
@export_range(0, 64, 1, "or_greater") var option_separation_px: int = 6
@export_range(4.0, 80.0, 0.1, "or_greater") var option_circle_radius_px: float = DEFAULT_OPTION_CIRCLE_RADIUS
@export_range(0.5, 16.0, 0.1, "or_greater") var option_circle_stroke_width_px: float = DEFAULT_OPTION_CIRCLE_STROKE_WIDTH
@export_range(0.0, 60.0, 0.1, "or_greater") var option_selected_dot_radius_px: float = DEFAULT_OPTION_SELECTED_DOT_RADIUS
@export var option_circle_fill_color: Color = DEFAULT_OPTION_CIRCLE_FILL_COLOR
@export var option_circle_outline_color: Color = DEFAULT_OPTION_CIRCLE_OUTLINE_COLOR
@export var option_circle_hover_color: Color = DEFAULT_OPTION_CIRCLE_HOVER_COLOR
@export var option_circle_selected_fill_color: Color = DEFAULT_OPTION_CIRCLE_SELECTED_FILL_COLOR
@export var option_circle_selected_color: Color = DEFAULT_OPTION_CIRCLE_SELECTED_COLOR
@export var option_circle_focus_color: Color = DEFAULT_OPTION_CIRCLE_FOCUS_COLOR
@export var option_line_enabled: bool = DEFAULT_OPTION_LINE_ENABLED
@export_range(0.0, 16.0, 0.1, "or_greater") var option_line_width_px: float = DEFAULT_OPTION_LINE_WIDTH
@export var option_line_color: Color = DEFAULT_OPTION_LINE_COLOR
@export_group("")
@export_group("Scroll Bar")
@export_range(1, 64, 1, "or_greater") var scrollbar_width_px: int = DEFAULT_SCROLLBAR_WIDTH:
	set(value):
		scrollbar_width_px = maxi(1, value)
		_update_scrollbar_theme()
@export_range(0, 32, 1, "or_greater") var scrollbar_corner_radius_px: int = DEFAULT_SCROLLBAR_CORNER_RADIUS:
	set(value):
		scrollbar_corner_radius_px = maxi(0, value)
		_update_scrollbar_theme()
@export var scrollbar_track_color: Color = DEFAULT_SCROLLBAR_TRACK_COLOR:
	set(value):
		scrollbar_track_color = value
		_update_scrollbar_theme()
@export var scrollbar_grabber_color: Color = DEFAULT_SCROLLBAR_GRABBER_COLOR:
	set(value):
		scrollbar_grabber_color = value
		_update_scrollbar_theme()
@export var scrollbar_grabber_hover_color: Color = DEFAULT_SCROLLBAR_GRABBER_HOVER_COLOR:
	set(value):
		scrollbar_grabber_hover_color = value
		_update_scrollbar_theme()
@export var scrollbar_grabber_pressed_color: Color = DEFAULT_SCROLLBAR_GRABBER_PRESSED_COLOR:
	set(value):
		scrollbar_grabber_pressed_color = value
		_update_scrollbar_theme()
@export_group("")
@export var title_font_size: int = 24
@export var label_font_size: int = DEFAULT_FONT_SIZE
@export var submit_button_font_size: int = DEFAULT_BUTTON_FONT_SIZE
@export var show_title_inside_panel: bool = true
var _spec: QuestionnaireSpec
var _pair_buttons: Dictionary = {}
var _submit_button: Button
var _progress_label: Label
var _warning_label: Label
var _title_label: Label
var _scroll_container: ScrollContainer
var _current_stimulus_id: String = ""
var _base_title: String = "SD Questionnaire"


func setup(spec: QuestionnaireSpec, p_title: String = "SD Questionnaire") -> void:
	_spec = spec
	_base_title = p_title
	_build_ui()
	reset_answers()


func popup_for_stimulus(
	stimulus_id: String,
	_stimulus_description: String = "",
	current_stimulus_number: int = 0,
	total_stimulus_count: int = 0
) -> void:
	_current_stimulus_id = stimulus_id
	_set_title(stimulus_id)
	_update_progress(current_stimulus_number, total_stimulus_count)
	show()
	_reset_scroll_position()
	_update_submit_state()


func reset_answers() -> void:
	for pair_id in _pair_buttons.keys():
		for button in _pair_buttons[pair_id]:
			button.button_pressed = false

	_current_stimulus_id = ""
	if is_instance_valid(_warning_label):
		_warning_label.text = ""
	_update_progress(0, 0)
	_set_title(_base_title)
	_reset_scroll_position()
	_update_submit_state()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	_pair_buttons.clear()
	_scroll_container = null
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
	margin.add_child(root)

	_title_label = Label.new()
	_title_label.text = _base_title
	_title_label.visible = show_title_inside_panel
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", title_font_size)
	root.add_child(_title_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll_container = scroll
	_apply_scrollbar_theme(scroll)
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", row_separation_px)
	scroll.add_child(list)

	if _spec == null:
		_warning_label = Label.new()
		_warning_label.text = "QuestionnaireSpec が設定されていません。"
		_warning_label.modulate = Color(0.85, 0.2, 0.2)
		root.add_child(_warning_label)
		return

	var pair_indices := _spec.build_adjective_pair_order()

	for i in pair_indices:
		var pair: Dictionary = _spec.adjective_pairs[i]
		var pair_id := str(pair.get("id", ""))
		var left := str(pair.get("left", ""))
		var right := str(pair.get("right", ""))

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		list.add_child(row)

		var left_label := Label.new()
		left_label.text = left
		left_label.custom_minimum_size = Vector2(label_width_px, DEFAULT_ROW_HEIGHT)
		left_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		left_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		left_label.add_theme_font_size_override("font_size", label_font_size)
		row.add_child(left_label)

		var options := OptionLineContainer.new()
		options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		options.alignment = BoxContainer.ALIGNMENT_CENTER
		options.add_theme_constant_override("separation", option_separation_px)
		options.line_enabled = option_line_enabled
		options.line_width_px = option_line_width_px
		options.line_color = option_line_color
		row.add_child(options)

		var group := ButtonGroup.new()
		group.allow_unpress = true

		var buttons: Array[BaseButton] = []
		for score in range(1, _spec.points + 1):
			var button := OptionCircleButton.new()
			button.button_group = group
			button.set_meta("score", score)
			button.toggled.connect(_on_option_toggled)
			button.custom_minimum_size = Vector2(option_button_size_px, option_button_size_px)
			button.circle_radius_px = option_circle_radius_px
			button.circle_stroke_width_px = option_circle_stroke_width_px
			button.selected_dot_radius_px = option_selected_dot_radius_px
			button.circle_fill_color = option_circle_fill_color
			button.circle_outline_color = option_circle_outline_color
			button.circle_hover_color = option_circle_hover_color
			button.circle_selected_fill_color = option_circle_selected_fill_color
			button.circle_selected_color = option_circle_selected_color
			button.circle_focus_color = option_circle_focus_color
			options.add_child(button)
			buttons.append(button)

		_pair_buttons[pair_id] = buttons

		var right_label := Label.new()
		right_label.text = right
		right_label.custom_minimum_size = Vector2(label_width_px, DEFAULT_ROW_HEIGHT)
		right_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		right_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		right_label.add_theme_font_size_override("font_size", label_font_size)
		row.add_child(right_label)

	_warning_label = Label.new()
	_warning_label.modulate = Color(0.85, 0.2, 0.2)
	_warning_label.text = ""
	root.add_child(_warning_label)

	var footer := Control.new()
	footer.name = "Footer"
	footer.custom_minimum_size = Vector2(0, 50)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(footer)

	var button_center := CenterContainer.new()
	button_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	footer.add_child(button_center)

	_submit_button = Button.new()
	_submit_button.name = "SubmitButton"
	_submit_button.text = "次へ"
	_submit_button.disabled = true
	_submit_button.custom_minimum_size = Vector2(120, 50)
	_submit_button.add_theme_font_size_override("font_size", submit_button_font_size)
	_submit_button.pressed.connect(_on_submit_pressed)
	button_center.add_child(_submit_button)

	var progress_container := MarginContainer.new()
	progress_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	footer.add_child(progress_container)

	_progress_label = Label.new()
	_progress_label.name = "ProgressLabel"
	_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	_progress_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", submit_button_font_size)
	progress_container.add_child(_progress_label)
	_update_progress(0, 0)


func _update_scrollbar_theme() -> void:
	if not is_instance_valid(_scroll_container):
		return
	_apply_scrollbar_theme(_scroll_container)


func _apply_scrollbar_theme(scroll: ScrollContainer) -> void:
	var v_scrollbar := scroll.get_v_scroll_bar()
	v_scrollbar.custom_minimum_size.x = scrollbar_width_px
	v_scrollbar.add_theme_stylebox_override("scroll", _make_scrollbar_stylebox(scrollbar_track_color))
	v_scrollbar.add_theme_stylebox_override("grabber", _make_scrollbar_stylebox(scrollbar_grabber_color))
	v_scrollbar.add_theme_stylebox_override("grabber_highlight", _make_scrollbar_stylebox(scrollbar_grabber_hover_color))
	v_scrollbar.add_theme_stylebox_override("grabber_pressed", _make_scrollbar_stylebox(scrollbar_grabber_pressed_color))


func _make_scrollbar_stylebox(color: Color) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = color
	var horizontal_margin := float(scrollbar_width_px) * 0.5
	stylebox.content_margin_left = horizontal_margin
	stylebox.content_margin_right = horizontal_margin
	stylebox.corner_radius_top_left = scrollbar_corner_radius_px
	stylebox.corner_radius_top_right = scrollbar_corner_radius_px
	stylebox.corner_radius_bottom_left = scrollbar_corner_radius_px
	stylebox.corner_radius_bottom_right = scrollbar_corner_radius_px
	return stylebox


func _set_title(value: String) -> void:
	if is_instance_valid(_title_label):
		_title_label.text = value


func _update_progress(current_stimulus_number: int, total_stimulus_count: int) -> void:
	if not is_instance_valid(_progress_label):
		return

	if current_stimulus_number <= 0 or total_stimulus_count <= 0:
		_progress_label.text = ""
		_progress_label.hide()
		return

	_progress_label.text = "%d/%d" % [current_stimulus_number, total_stimulus_count]
	_progress_label.show()


func _reset_scroll_position() -> void:
	if not is_instance_valid(_scroll_container):
		return

	_scroll_container.scroll_vertical = 0
	_scroll_container.set_deferred("scroll_vertical", 0)


func _on_option_toggled(_pressed: bool) -> void:
	_update_submit_state()


func _update_submit_state() -> void:
	if not is_instance_valid(_submit_button):
		return

	for pair_id in _pair_buttons.keys():
		var has_value := false
		for button in _pair_buttons[pair_id]:
			if button.button_pressed:
				has_value = true
				break
		if not has_value:
			_submit_button.disabled = true
			return

	_submit_button.disabled = false


func _on_submit_pressed() -> void:
	var answers := _collect_answers()

	_warning_label.text = ""
	_reset_scroll_position()
	var submitted_stimulus_id := _current_stimulus_id
	hide()
	emit_signal("submitted", submitted_stimulus_id, answers)


func _collect_answers() -> Dictionary:
	var answers := {}

	for pair_id in _pair_buttons.keys():
		for button in _pair_buttons[pair_id]:
			if button.button_pressed:
				answers[pair_id] = int(button.get_meta("score"))
				break

	return answers

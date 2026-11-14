class_name ControlsHint
extends Control
## Guia de teclas no canto superior direito. Cada tecla acende enquanto é apertada.

# [rótulo da ação, [[texto da tecla, [teclas físicas]], ...]]
const ROWS := [
	["Mover", [["A", [KEY_A, KEY_LEFT]], ["D", [KEY_D, KEY_RIGHT]]]],
	["Correr", [["Shift", [KEY_SHIFT]]]],
	["Pular", [["Espaço", [KEY_SPACE, KEY_W, KEY_UP]]]],
	["Inventário", [["I", [KEY_I]], ["Tab", [KEY_TAB]]]],
	["Pausa", [["Esc", [KEY_ESCAPE]]]],
]

var _caps: Array = []   # {"panel": PanelContainer, "label": Label, "keys": Array, "down": bool}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var wrapper := MarginContainer.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_theme_constant_override("margin_top", 16)
	wrapper.add_theme_constant_override("margin_right", 16)
	add_child(wrapper)
	wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(column)

	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_END
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(line)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UIStyle.box(Color(UIStyle.PANEL, 0.88), UIStyle.CELL, 2, 6, 10))
	line.add_child(panel)

	var rows_box := VBoxContainer.new()
	rows_box.add_theme_constant_override("separation", 6)
	panel.add_child(rows_box)

	for row in ROWS:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		rows_box.add_child(h)

		var name_label := Label.new()
		name_label.text = row[0]
		name_label.custom_minimum_size = Vector2(84, 0)
		name_label.add_theme_color_override("font_color", UIStyle.MUTED)
		name_label.add_theme_font_size_override("font_size", 13)
		h.add_child(name_label)

		for cap in row[1]:
			h.add_child(_make_cap(str(cap[0]), cap[1]))


func _make_cap(text: String, keys: Array) -> Control:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(28, 26)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	panel.add_child(label)
	var cap := {"panel": panel, "label": label, "keys": keys, "down": false}
	_caps.append(cap)
	_style_cap(cap, false)
	return panel


func _style_cap(cap: Dictionary, down: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIStyle.YELLOW if down else UIStyle.CELL
	sb.border_color = UIStyle.YELLOW_LIGHT if down else Color(0.07, 0.10, 0.15)
	sb.border_width_bottom = 1 if down else 3
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 2
	sb.content_margin_bottom = 1 if down else 3
	(cap["panel"] as PanelContainer).add_theme_stylebox_override("panel", sb)
	(cap["label"] as Label).add_theme_color_override("font_color", UIStyle.DARK if down else UIStyle.TEXT)
	cap["down"] = down


func _process(_delta: float) -> void:
	for cap in _caps:
		var down := false
		for k in cap["keys"]:
			if Input.is_physical_key_pressed(k):
				down = true
				break
		if down != cap["down"]:
			_style_cap(cap, down)

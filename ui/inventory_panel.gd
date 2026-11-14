class_name InventoryPanel
extends Control
## Tela cheia de inventário: tabela periódica (esquerda) + combinar e receitas (direita).
##
## Como combinar: clique nos elementos da tabela (clique de novo no mesmo para usar mais de um),
## depois em "Combinar". Clique num espaço para esvaziá-lo.
## "Separar" desfaz o composto mostrado no resultado (clique numa receita descoberta para mostrá-lo).

signal hint_requested

const COLS := 18
const TABLE_ROWS := 10                # 7 períodos + linha em branco (8) + lantanídeos (9) + actinídeos (10)
const CELL_SIZE := Vector2(36, 36)
const USE_SUBSCRIPTS := true          # se o "₂" aparecer como quadradinho, troque por false

var _by_pos: Dictionary = {}          # Vector2i(coluna, linha) -> dados do elemento (PeriodicTable)
var _cells: Dictionary = {}           # Vector2i(coluna, linha) -> {"panel": Panel, "label": Label}
var _info_title: Label
var _info_meta: Label
var _info_desc: Label
var _recipes_box: VBoxContainer
var _query: String = ""
var _hint_level: int = 0               # 0 a 3: cada clique em Dica mostra uma pista maior

# Área de combinação
var _slot_ids: Array = ["", ""]       # id do elemento em cada espaço (A e B)
var _slot_counts: Array = [0, 0]      # quantidade em cada espaço
var _slot_panels: Array = []
var _slot_labels: Array = []
var _result_panel: Panel
var _result_label: Label
var _status: Label
var _last_recipe: RecipeData = null   # composto mostrado no espaço de resultado


func _ready() -> void:
	for entry in PeriodicTable.entries():
		_by_pos[Vector2i(entry["col"], entry["row"])] = entry
	_build_ui()
	Inventory.changed.connect(refresh)
	refresh()


# ------------------------------------------------------------------ construção da UI
func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = UIStyle.BG
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 40)
	margin.add_child(root)
	root.add_child(_build_left())
	root.add_child(_build_right())


func _build_left() -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)

	var title := Label.new()
	title.text = "INVENTÁRIO · TABELA PERIÓDICA"
	UIStyle.style_title(title, 24)
	box.add_child(title)

	var intro := Label.new()
	intro.text = "A tabela periódica completa: os elementos em amarelo são os que você já coletou."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(500, 0)
	intro.add_theme_color_override("font_color", UIStyle.TEXT)
	box.add_child(intro)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	box.add_child(grid)
	for row in range(1, TABLE_ROWS + 1):
		for col in range(1, COLS + 1):
			grid.add_child(_make_cell(col, row))

	var note := Label.new()
	note.text = "Amarelo: coletado · Cinza: ainda não coletado · Escuro: ainda não disponível no jogo."
	note.add_theme_color_override("font_color", UIStyle.MUTED)
	box.add_child(note)

	# Descrição do elemento (aparece ao passar o mouse ou clicar numa célula)
	var info := PanelContainer.new()
	info.custom_minimum_size = Vector2(0, 104)
	info.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.CELL, 2, 4, 14))
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 6)
	info.add_child(iv)

	_info_title = Label.new()
	UIStyle.style_title(_info_title, 18)
	iv.add_child(_info_title)

	_info_meta = Label.new()
	_info_meta.add_theme_color_override("font_color", UIStyle.MUTED)
	iv.add_child(_info_meta)

	_info_desc = Label.new()
	_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_desc.custom_minimum_size = Vector2(500, 0)
	_info_desc.add_theme_color_override("font_color", UIStyle.TEXT)
	iv.add_child(_info_desc)

	box.add_child(info)
	_show_default_info()
	return box


func _build_right() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(390, 0)
	panel.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.YELLOW, 3, 0, 20))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var header := HBoxContainer.new()
	v.add_child(header)

	var t1 := Label.new()
	t1.text = "COMBINAR"
	t1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIStyle.style_title(t1, 20)
	header.add_child(t1)

	var hint := _make_button("? Dica", UIStyle.CELL, UIStyle.YELLOW)
	hint.size_flags_horizontal = Control.SIZE_SHRINK_END
	hint.custom_minimum_size = Vector2(96, 36)
	hint.pressed.connect(_on_hint_pressed)
	header.add_child(hint)

	# Espaços de combinação: A + B = resultado
	var slot_a := _make_slot()
	var slot_b := _make_slot()
	var slot_r := _make_slot()
	var pa: Panel = slot_a["panel"]
	var pb: Panel = slot_b["panel"]
	_slot_panels = [pa, pb]
	_slot_labels = [slot_a["label"], slot_b["label"]]
	_result_panel = slot_r["panel"]
	_result_label = slot_r["label"]
	pa.gui_input.connect(_on_slot_input.bind(0))
	pb.gui_input.connect(_on_slot_input.bind(1))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(pa)
	row.add_child(_make_op("+"))
	row.add_child(pb)
	row.add_child(_make_op("="))
	row.add_child(_result_panel)
	v.add_child(row)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	var combine := _make_button("Combinar", UIStyle.YELLOW, UIStyle.DARK)
	var separate := _make_button("Separar", UIStyle.CELL, UIStyle.TEXT)
	combine.pressed.connect(_on_combine_pressed)
	separate.pressed.connect(_on_separate_pressed)
	buttons.add_child(combine)
	buttons.add_child(separate)
	v.add_child(buttons)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(340, 72)
	_status.add_theme_color_override("font_color", UIStyle.YELLOW)
	_status.add_theme_font_size_override("font_size", 14)
	_status.text = "Clique nos elementos da tabela para escolher o que combinar."
	v.add_child(_status)

	var t2 := Label.new()
	t2.text = "RECEITAS"
	UIStyle.style_title(t2, 18)
	v.add_child(t2)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 120)
	v.add_child(scroll)

	_recipes_box = VBoxContainer.new()
	_recipes_box.add_theme_constant_override("separation", 6)
	_recipes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_recipes_box)

	var search := LineEdit.new()
	search.placeholder_text = "Pesquisar receita..."
	search.add_theme_stylebox_override("normal", UIStyle.box(UIStyle.CELL, UIStyle.NO_BORDER, 0, 3, 10))
	search.add_theme_stylebox_override("focus", UIStyle.box(UIStyle.CELL_HOVER, UIStyle.YELLOW, 2, 3, 10))
	search.text_changed.connect(_on_search_changed)
	v.add_child(search)

	var foot := Label.new()
	foot.text = "Combinações fora da lista não reagem, e nada de ruim acontece."
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.custom_minimum_size = Vector2(340, 0)
	foot.add_theme_color_override("font_color", UIStyle.MUTED)
	foot.add_theme_font_size_override("font_size", 13)
	v.add_child(foot)

	_update_slots()
	_clear_result()
	return panel


func _make_cell(col: int, row: int) -> Control:
	if row == 8:   # linha em branco entre a tabela principal e lantanídeos/actinídeos
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(CELL_SIZE.x, 10)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return gap

	var key := Vector2i(col, row)
	if not _by_pos.has(key):
		# posição vazia, ou marcador "57–71" / "89–103" (onde ficam lantanídeos e actinídeos)
		var holder := Control.new()
		holder.custom_minimum_size = CELL_SIZE
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var marker := ""
		if col == 3 and row == 6:
			marker = "57–71"
		elif col == 3 and row == 7:
			marker = "89–103"
		if marker != "":
			var m := Label.new()
			m.text = marker
			m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			m.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			m.add_theme_font_size_override("font_size", 10)
			m.add_theme_color_override("font_color", UIStyle.FAINT_TEXT)
			holder.add_child(m)
			m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return holder

	var cell := Panel.new()
	cell.custom_minimum_size = CELL_SIZE
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_cells[key] = {"panel": cell, "label": label}
	cell.mouse_entered.connect(_on_cell_hover.bind(key))
	cell.gui_input.connect(_on_cell_input.bind(key))
	return cell


func _make_slot() -> Dictionary:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(64, 64)
	var label := Label.new()
	label.text = "?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return {"panel": slot, "label": label}


func _make_op(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", UIStyle.TEXT)
	label.add_theme_font_size_override("font_size", 20)
	return label


func _make_button(text: String, bg: Color, fg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 48)
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, UIStyle.box(bg, UIStyle.NO_BORDER, 0, 3))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)
	b.add_theme_font_size_override("font_size", 16)
	return b


# ------------------------------------------------------------------ atualização
func refresh() -> void:
	for key in _cells:
		var cell: Panel = _cells[key]["panel"]
		var label: Label = _cells[key]["label"]
		var entry: Dictionary = _by_pos[key]
		var e: ElementData = Database.get_element(str(entry["symbol"]).to_lower())
		if e != null and Inventory.has_element(e.id):
			# coletado: amarelo, borda clara e símbolo grande
			cell.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.YELLOW, UIStyle.YELLOW_LIGHT, 2, 3))
			label.text = e.symbol
			UIStyle.style_symbol(label, UIStyle.DARK, 16)
		elif e != null:
			# existe no jogo, mas ainda não foi coletado
			cell.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.CELL, UIStyle.NO_BORDER, 0, 3))
			label.text = e.symbol
			UIStyle.style_symbol(label, UIStyle.LOCKED_TEXT, 13)
		else:
			# ainda não existe no jogo
			cell.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.UNAVAILABLE, UIStyle.NO_BORDER, 0, 3))
			label.text = str(entry["symbol"])
			UIStyle.style_symbol(label, UIStyle.FAINT_TEXT, 11)
	_clamp_slots()
	_update_slots()
	_refresh_recipes()


func _refresh_recipes() -> void:
	for child in _recipes_box.get_children():
		_recipes_box.remove_child(child)
		child.queue_free()

	for recipe in Database.recipes:
		var found := Inventory.is_discovered(recipe.id)
		var text := "? + ? → ??? · ainda não descoberta"
		if found:
			text = "%s → %s (%s)" % [_inputs_text(recipe), _fmt(recipe.result_formula), recipe.result_name.to_lower()]
		if not _query.is_empty():
			if not found or text.to_lower().find(_query.to_lower()) == -1:
				continue
		_recipes_box.add_child(_make_recipe_row(recipe, text, found))


func _make_recipe_row(recipe: RecipeData, text: String, found: bool) -> Control:
	var row := PanelContainer.new()
	var bg := Color(0.07, 0.11, 0.16) if found else UIStyle.CELL
	row.add_theme_stylebox_override("panel", UIStyle.box(bg, UIStyle.NO_BORDER, 0, 3, 8))
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(320, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", UIStyle.TEXT if found else UIStyle.MUTED)
	label.add_theme_font_size_override("font_size", 14)
	row.add_child(label)
	if found:
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_recipe_row_input.bind(recipe))
	return row


func _inputs_text(recipe: RecipeData) -> String:
	var parts: Array[String] = []
	for id in recipe.inputs:
		var e := Database.get_element(str(id))
		var sym: String = e.symbol if e != null else str(id)
		var n := int(recipe.inputs[id])
		parts.append(sym if n == 1 else "%d %s" % [n, sym])
	return " + ".join(parts)


func _fmt(formula: String) -> String:
	if not USE_SUBSCRIPTS:
		return formula
	var subs := ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
	var out := ""
	for ch in formula:
		if ch >= "0" and ch <= "9":
			out += subs[int(ch)]
		else:
			out += ch
	return out


# ------------------------------------------------------------------ espaços de combinação
func _update_slots() -> void:
	var colors := [Color(0.92, 0.94, 1.0), Color(0.949, 0.545, 0.510)]
	for i in 2:
		var panel: Panel = _slot_panels[i]
		var label: Label = _slot_labels[i]
		if _slot_ids[i] == "":
			panel.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.CELL, UIStyle.NO_BORDER, 0, 3))
			label.text = "?"
			UIStyle.style_symbol(label, UIStyle.MUTED, 22)
		else:
			var e := Database.get_element(_slot_ids[i])
			var sym: String = e.symbol if e != null else "?"
			panel.add_theme_stylebox_override("panel", UIStyle.box(colors[i], UIStyle.NO_BORDER, 0, 3))
			label.text = sym if _slot_counts[i] == 1 else "%d%s" % [_slot_counts[i], sym]
			UIStyle.style_symbol(label, UIStyle.DARK, 22)


func _clear_slots() -> void:
	_slot_ids = ["", ""]
	_slot_counts = [0, 0]
	_update_slots()


## Garante que os espaços nunca usem mais do que o jogador realmente tem.
func _clamp_slots() -> void:
	for i in 2:
		if _slot_ids[i] == "":
			continue
		var owned := Inventory.count_of(_slot_ids[i])
		if owned <= 0:
			_slot_ids[i] = ""
			_slot_counts[i] = 0
		else:
			_slot_counts[i] = mini(_slot_counts[i], owned)


func _show_result(recipe: RecipeData) -> void:
	_last_recipe = recipe
	_result_panel.add_theme_stylebox_override("panel", UIStyle.box(Color(0.498, 0.82, 0.91), UIStyle.NO_BORDER, 0, 3))
	_result_label.text = _fmt(recipe.result_formula)
	UIStyle.style_symbol(_result_label, UIStyle.DARK, 18)


func _clear_result() -> void:
	_last_recipe = null
	_result_panel.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.CELL, UIStyle.NO_BORDER, 0, 3))
	_result_label.text = "?"
	UIStyle.style_symbol(_result_label, UIStyle.MUTED, 22)


func _set_status(text: String) -> void:
	_status.text = text


func _select_element(e: ElementData) -> void:
	_clear_result()
	var owned := Inventory.count_of(e.id)

	# Já está num espaço: aumenta a quantidade (ex.: 2 H)
	for i in 2:
		if _slot_ids[i] == e.id:
			if _slot_counts[i] < owned:
				_slot_counts[i] += 1
				_set_status("")
			else:
				_set_status("Você só tem %d de %s." % [owned, e.display_name.to_lower()])
			_update_slots()
			return

	# Senão, ocupa o primeiro espaço livre
	for i in 2:
		if _slot_ids[i] == "":
			_slot_ids[i] = e.id
			_slot_counts[i] = 1
			_set_status("")
			_update_slots()
			return

	_set_status("Os dois espaços estão cheios. Clique em um espaço para esvaziá-lo.")


func _on_combine_pressed() -> void:
	var inputs: Dictionary = {}
	for i in 2:
		if _slot_ids[i] != "":
			inputs[_slot_ids[i]] = int(_slot_counts[i])

	if inputs.is_empty():
		_set_status("Escolha elementos na tabela para combinar.")
		return

	var recipe := Database.find_recipe(inputs)
	if recipe == null:
		GameAudio.play_sfx("erro")
		_set_status("Esses elementos não reagem. Nada de ruim acontece.")
		return

	var first_time := not Inventory.is_discovered(recipe.id)
	for id in inputs:
		Inventory.remove_element(str(id), int(inputs[id]))
	Inventory.add_compound(recipe.id)
	_hint_level = 0
	Inventory.discover_recipe(recipe.id)

	_clear_slots()
	_show_result(recipe)
	var head := "Nova receita! " if first_time else "Você formou: "
	_set_status("%s%s (%s). %s" % [head, recipe.result_name, _fmt(recipe.result_formula), recipe.explanation])


func _on_separate_pressed() -> void:
	if _last_recipe != null and Inventory.compound_count(_last_recipe.id) > 0:
		var r := _last_recipe
		Inventory.remove_compound(r.id)
		for id in r.inputs:
			Inventory.add_element(str(id), int(r.inputs[id]), false)
		_clear_result()
		GameAudio.play_sfx("separar")
		_set_status("%s foi separada em %s." % [r.result_name, _inputs_text(r)])
	elif _last_recipe != null:
		_set_status("Você ainda não tem %s para separar." % _last_recipe.result_name.to_lower())
	elif _slot_ids[0] != "" or _slot_ids[1] != "":
		_clear_slots()
		_set_status("Seleção desfeita.")
	else:
		_set_status("Nada para separar. Clique numa receita descoberta para escolher o composto.")


func _on_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _slot_ids[index] != "":
			_slot_ids[index] = ""
			_slot_counts[index] = 0
			_update_slots()
			_set_status("")


func _on_recipe_row_input(event: InputEvent, recipe: RecipeData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_result(recipe)
		_set_status("%s: você tem %d. Aperte Separar para devolver os elementos." % [recipe.result_name, Inventory.compound_count(recipe.id)])


# ------------------------------------------------------------------ descrição do elemento
func _show_default_info() -> void:
	_info_title.text = "Descrição do elemento"
	_info_meta.text = ""
	_info_desc.text = "Passe o mouse (ou clique) sobre um elemento da tabela para ver a descrição."


func _show_info(key: Vector2i) -> void:
	if not _by_pos.has(key):
		return
	var entry: Dictionary = _by_pos[key]
	var e: ElementData = Database.get_element(str(entry["symbol"]).to_lower())
	if e == null:
		_info_title.text = "%s (%s)" % [entry["name"], entry["symbol"]]
		_info_meta.text = "Nº atômico %d · %s · ainda não disponível no jogo" % [entry["z"], entry["category"]]
		_info_desc.text = "Este elemento ainda não foi adicionado ao jogo. Ele poderá aparecer em fases futuras."
	elif not Inventory.has_element(e.id):
		_info_title.text = "%s (%s)" % [e.display_name, e.symbol]
		_info_meta.text = "Nº atômico %d · %s · ainda não coletado" % [e.atomic_number, e.category]
		_info_desc.text = "Colete este elemento nas fases para ver a descrição."
	else:
		_info_title.text = "%s (%s)" % [e.display_name, e.symbol]
		_info_meta.text = "Nº atômico %d · %s · você tem: %d" % [e.atomic_number, e.category, Inventory.count_of(e.id)]
		_info_desc.text = e.description


func _on_cell_hover(key: Vector2i) -> void:
	_show_info(key)


func _on_cell_input(event: InputEvent, key: Vector2i) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_info(key)
		if not _by_pos.has(key):
			return
		var entry: Dictionary = _by_pos[key]
		var e: ElementData = Database.get_element(str(entry["symbol"]).to_lower())
		if e != null and Inventory.has_element(e.id):
			_select_element(e)


func _on_search_changed(text: String) -> void:
	_query = text.strip_edges()
	_refresh_recipes()


# ------------------------------------------------------------------ dicas
## Cada clique em "? Dica" mostra uma pista maior: 1 = objetivo, 2 = pista, 3 = receita completa.
func _on_hint_pressed() -> void:
	_hint_level = mini(_hint_level + 1, 3)
	_set_status(_build_hint(_hint_level))
	hint_requested.emit()


func _build_hint(level: int) -> String:
	var mission := Progress.current_mission
	if mission == null:
		return "Escolha elementos na tabela e aperte Combinar para ver o que acontece. Combinações erradas não têm penalidade."
	if Inventory.items.is_empty() and Inventory.compounds.is_empty():
		return "Você ainda não coletou elementos. Explore a fase e toque nos blocos amarelos; depois volte aqui para combiná-los."

	var target := _next_target_recipe(mission)
	if target == null:
		return "Você já descobriu todos os compostos desta missão! Tente receitas extras ou volte ao menu para escolher outra fase."

	if level == 1:
		return "Missão: %s. %s Clique nos elementos para escolhê-los e aperte Combinar. Aperte Dica de novo para uma pista." % [mission.title, mission.description]
	if level == 2:
		return "Pista: um dos compostos que faltam usa %s. Aperte Dica de novo para ver a receita." % _symbols_text(target)
	return "Receita: %s → %s. %s" % [_inputs_text(target), _fmt(target.result_formula), _missing_text(target)]


## Escolhe o próximo composto da missão que ainda não deu estrela (prefere um que o jogador já consegue montar).
func _next_target_recipe(mission: MissionData) -> RecipeData:
	var candidates: Array[RecipeData] = []
	for recipe in Database.recipes:
		var in_mission: bool = recipe.category == mission.required_category
		if not mission.recipe_ids.is_empty():
			in_mission = mission.recipe_ids.has(recipe.id)
		if in_mission and not Progress.stars.has(recipe.method_id):
			candidates.append(recipe)
	for recipe in candidates:
		if _can_make(recipe):
			return recipe
	if candidates.is_empty():
		return null
	return candidates[0]


func _can_make(recipe: RecipeData) -> bool:
	for id in recipe.inputs:
		if Inventory.count_of(str(id)) < int(recipe.inputs[id]):
			return false
	return true


func _symbols_text(recipe: RecipeData) -> String:
	var parts: Array[String] = []
	for id in recipe.inputs:
		var e := Database.get_element(str(id))
		parts.append(e.symbol if e != null else str(id))
	return " e ".join(parts)


func _missing_text(recipe: RecipeData) -> String:
	var parts: Array[String] = []
	for id in recipe.inputs:
		var lack := int(recipe.inputs[id]) - Inventory.count_of(str(id))
		if lack > 0:
			var e := Database.get_element(str(id))
			parts.append("%d %s" % [lack, e.symbol if e != null else str(id)])
	if parts.is_empty():
		return "Você já tem tudo: selecione os elementos e aperte Combinar."
	return "Ainda faltam: %s. Colete mais na fase." % ", ".join(parts)

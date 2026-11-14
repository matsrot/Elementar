class_name LevelSelect
extends Control
## Seleção de fase: título, descrição e estrelas conquistadas de cada fase.

signal closed
signal level_chosen(scene_path: String)

var _cards: HFlowContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = UIStyle.BG
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	margin.add_child(v)

	var title := Label.new()
	title.text = "ESCOLHER FASE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyle.style_title(title, 36)
	v.add_child(title)

	var hint := Label.new()
	hint.text = "Cada composto diferente que você formar vale uma estrela. Suas estrelas ficam salvas."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", UIStyle.MUTED)
	v.add_child(hint)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(center)

	_cards = HFlowContainer.new()
	_cards.alignment = FlowContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("h_separation", 24)
	_cards.add_theme_constant_override("v_separation", 24)
	_cards.custom_minimum_size = Vector2(760, 0)
	center.add_child(_cards)

	var back := Button.new()
	back.text = "Voltar"
	back.custom_minimum_size = Vector2(240, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyle.style_button(back, UIStyle.CELL, UIStyle.TEXT)
	back.pressed.connect(func() -> void: closed.emit())
	v.add_child(back)

	refresh()


## Recria os cartões (chame ao mostrar a tela, para atualizar as estrelas).
func refresh() -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for level in Database.levels:
		_cards.add_child(_make_card(level))


func _make_card(level: LevelData) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 0)
	panel.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.YELLOW, 3, 6, 20))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var title := Label.new()
	title.text = level.title
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(300, 0)
	UIStyle.style_title(title, 20)
	v.add_child(title)

	var desc := Label.new()
	desc.text = level.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(300, 110)
	desc.add_theme_color_override("font_color", UIStyle.TEXT)
	desc.add_theme_font_size_override("font_size", 15)
	v.add_child(desc)

	var total := Progress.total_for(level.mission)
	var got := 0
	if level.mission != null:
		got = mini(Progress.saved_stars(level.mission.id), total)
	var stars := Label.new()
	stars.text = "%s%s   %d / %d" % ["★".repeat(got), "☆".repeat(maxi(total - got, 0)), got, total]
	stars.add_theme_color_override("font_color", UIStyle.YELLOW)
	stars.add_theme_font_size_override("font_size", 22)
	v.add_child(stars)

	var unlocked := _is_unlocked(level)
	if not unlocked:
		var req := Database.get_level(level.unlock_level_id)
		var lock := Label.new()
		lock.text = "Bloqueada: ganhe pelo menos %d estrela(s) na %s para liberar." % [level.unlock_stars, req.title]
		lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lock.custom_minimum_size = Vector2(300, 0)
		lock.add_theme_color_override("font_color", UIStyle.MUTED)
		lock.add_theme_font_size_override("font_size", 14)
		v.add_child(lock)
		panel.modulate = Color(1, 1, 1, 0.75)

	var play := Button.new()
	play.text = "Jogar" if unlocked else "Bloqueada"
	play.custom_minimum_size = Vector2(0, 48)
	UIStyle.style_button(play, UIStyle.YELLOW if unlocked else UIStyle.CELL, UIStyle.DARK if unlocked else UIStyle.MUTED)
	play.disabled = level.scene.is_empty() or not unlocked
	play.pressed.connect(_on_play.bind(level.scene))
	v.add_child(play)
	return panel


func _is_unlocked(level: LevelData) -> bool:
	if level.unlock_level_id.is_empty():
		return true
	var req := Database.get_level(level.unlock_level_id)
	if req == null or req.mission == null:
		return true
	return Progress.saved_stars(req.mission.id) >= level.unlock_stars


func _on_play(scene_path: String) -> void:
	level_chosen.emit(scene_path)

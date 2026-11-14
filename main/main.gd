extends Control
## Tela inicial do Elementar: Iniciar, Configurações e Sair.

var _menu_box: VBoxContainer
var _settings: SettingsPanel
var _level_select: LevelSelect
var _floaters: Array = []             # blocos de elementos que flutuam no fundo
var _symbols := PackedStringArray()   # símbolos usados nos blocos flutuantes

const FLOATER_COUNT := 28


func _ready() -> void:
	SettingsPanel.apply_saved()
	_build_ui()
	GameAudio.play_music("musica_menu")


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_build_background()

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 18)
	center.add_child(_menu_box)

	var title := Label.new()
	title.text = "ELEMENTAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyle.style_title(title, 72)
	_menu_box.add_child(title)
	# o título "respira": alterna suavemente entre branco e amarelo claro
	var pulse := create_tween().set_loops()
	pulse.tween_property(title, "modulate", Color(1.0, 0.94, 0.72), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(title, "modulate", Color.WHITE, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var bar := ColorRect.new()
	bar.color = UIStyle.YELLOW
	bar.custom_minimum_size = Vector2(180, 4)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu_box.add_child(bar)

	var subtitle := Label.new()
	subtitle.text = "Aprenda a Tabela Periódica jogando"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", UIStyle.MUTED)
	subtitle.add_theme_font_size_override("font_size", 20)
	_menu_box.add_child(subtitle)

	# Fileira decorativa com os elementos do protótipo
	var tiles := HBoxContainer.new()
	tiles.alignment = BoxContainer.ALIGNMENT_CENTER
	tiles.add_theme_constant_override("separation", 8)
	for symbol in ["H", "C", "N", "O", "Na", "Cl", "K", "Ca", "Fe"]:
		tiles.add_child(_make_tile(symbol))
	_menu_box.add_child(tiles)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	_menu_box.add_child(spacer)

	var start := _make_button("Iniciar", true)
	start.pressed.connect(_on_start)
	_menu_box.add_child(start)

	var settings := _make_button("Configurações", false)
	settings.pressed.connect(_on_settings)
	_menu_box.add_child(settings)

	var quit := _make_button("Sair", false)
	quit.pressed.connect(_on_quit)
	_menu_box.add_child(quit)

	var version := Label.new()
	version.text = "Protótipo · TCC Sistemas de Informação · FAFRAM"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_color_override("font_color", UIStyle.MUTED)
	version.add_theme_font_size_override("font_size", 13)
	_menu_box.add_child(version)

	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(_on_settings_closed)
	center.add_child(_settings)

	_level_select = LevelSelect.new()
	_level_select.visible = false
	_level_select.closed.connect(_on_levels_closed)
	_level_select.level_chosen.connect(_on_level_chosen)
	add_child(_level_select)   # cobre a tela inteira


func _make_tile(symbol: String) -> Control:
	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(56, 56)
	tile.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.YELLOW, UIStyle.NO_BORDER, 0, 4))
	var label := Label.new()
	label.text = symbol
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyle.style_symbol(label, UIStyle.DARK, 22)
	tile.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return tile


func _make_button(text: String, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 52)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if primary:
		UIStyle.style_button(b, UIStyle.YELLOW, UIStyle.DARK, 18)
	else:
		UIStyle.style_button(b, UIStyle.CELL, UIStyle.TEXT, 18)
	return b


func _on_start() -> void:
	_level_select.refresh()
	_menu_box.visible = false
	_level_select.visible = true


func _on_levels_closed() -> void:
	_level_select.visible = false
	_menu_box.visible = true


func _on_level_chosen(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


func _on_settings() -> void:
	_menu_box.visible = false
	_settings.visible = true


func _on_settings_closed() -> void:
	_settings.visible = false
	_menu_box.visible = true


func _on_quit() -> void:
	get_tree().quit()


# ------------------------------------------------------------------ fundo decorado
func _build_background() -> void:
	# Degradê azul-marinho (mais claro embaixo)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.045, 0.075, 0.13), Color(0.12, 0.20, 0.34)])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 256
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Blocos de elementos que sobem devagar, com símbolos de toda a tabela periódica
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_symbols = PeriodicTable.symbols()
	var area := get_viewport_rect().size
	for i in FLOATER_COUNT:
		var tile := _make_floater(_symbols, area, true)
		layer.add_child(tile)
		_floaters.append(tile)


func _make_floater(symbols: PackedStringArray, area: Vector2, random_y: bool) -> Panel:
	var s := randf_range(34.0, 64.0)
	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(s, s)
	tile.size = Vector2(s, s)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tint := UIStyle.YELLOW if randf() < 0.18 else UIStyle.CELL_HOVER
	tile.add_theme_stylebox_override("panel", UIStyle.box(tint, UIStyle.NO_BORDER, 0, int(s * 0.1)))
	tile.modulate.a = randf_range(0.07, 0.17)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", int(s * 0.42))
	label.add_theme_color_override("font_color", UIStyle.DARK if tint == UIStyle.YELLOW else UIStyle.TEXT)
	tile.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reset_floater(tile, symbols, area, random_y)
	return tile


func _reset_floater(tile: Panel, symbols: PackedStringArray, area: Vector2, random_y: bool) -> void:
	(tile.get_child(0) as Label).text = symbols[randi() % symbols.size()]
	var x := randf_range(0.0, maxf(area.x - tile.size.x, 1.0))
	var y := randf_range(0.0, area.y) if random_y else area.y + 10.0
	tile.position = Vector2(x, y)
	tile.set_meta("speed", randf_range(10.0, 28.0))
	tile.set_meta("phase", randf() * TAU)


func _process(delta: float) -> void:
	var area := get_viewport_rect().size
	var t := Time.get_ticks_msec() / 1000.0
	for tile in _floaters:
		var p := tile as Panel
		p.position.y -= float(p.get_meta("speed")) * delta
		p.position.x += sin(t + float(p.get_meta("phase"))) * 6.0 * delta
		if p.position.y < -p.size.y:
			_reset_floater(p, _symbols, area, false)

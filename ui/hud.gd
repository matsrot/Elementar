extends CanvasLayer
## HUD: tecla I abre/fecha o inventário, balão ao coletar, marcador da missão,
## balão de "missão cumprida" e aviso de novas estrelas.

var _inventory: InventoryPanel
var _toast: PanelContainer
var _toast_title: Label
var _toast_desc: Label
var _toast_tween: Tween

var _tracker: PanelContainer
var _tracker_title: Label
var _tracker_desc: Label
var _tracker_stars: Label

var _popup: Control
var _popup_mission: Label
var _popup_text: Label
var _popup_stars: Label
var _popup_next: Button
var _next_scene: String = ""

var _pause: Control
var _tutorial: Tutorial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # continua funcionando com o jogo pausado
	layer = 10
	_build_tracker()                           # fica atrás do inventário
	add_child(ControlsHint.new())              # guia de teclas (também atrás do inventário)
	_inventory = InventoryPanel.new()
	_inventory.visible = false
	add_child(_inventory)
	_build_toast()                             # os balões ficam na frente do inventário
	_tutorial = Tutorial.new()
	add_child(_tutorial)
	_inventory.hint_requested.connect(_on_hint_requested)
	_build_popup()
	_build_pause()

	Inventory.element_collected.connect(_on_element_collected)
	Progress.mission_started.connect(_on_mission_started)
	Progress.star_earned.connect(_on_star_earned)
	Progress.mission_completed.connect(_on_mission_completed)
	_update_tracker()


## Tab também abre/fecha o inventário. Fica em _input (e não em _unhandled_input)
## porque o Godot usa o Tab para navegar entre botões antes de chegar lá.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		if _popup.visible or _pause.visible:
			return
		_set_inventory_open(not _inventory.visible)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _popup.visible:
		if event.is_action_pressed("ui_cancel"):
			_popup.visible = false
			get_viewport().set_input_as_handled()
		return
	if _pause.visible:
		if event.is_action_pressed("ui_cancel"):
			_set_pause_open(false)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventario"):
		_set_inventory_open(not _inventory.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if _inventory.visible:
			_set_inventory_open(false)
		else:
			_set_pause_open(true)
		get_viewport().set_input_as_handled()


func _set_inventory_open(open: bool) -> void:
	_inventory.visible = open
	get_tree().paused = open
	if open:
		_inventory.refresh()
		_tutorial.notify_event("inventory")


# ------------------------------------------------------------------ marcador da missão
func _build_tracker() -> void:
	_tracker = PanelContainer.new()
	_tracker.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.YELLOW, 2, 4, 12))
	_tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tracker.custom_minimum_size = Vector2(300, 0)
	_tracker.position = Vector2(16, 16)
	_tracker.visible = false
	add_child(_tracker)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_tracker.add_child(v)

	_tracker_title = Label.new()
	_tracker_title.add_theme_color_override("font_color", UIStyle.TEXT)
	_tracker_title.add_theme_font_size_override("font_size", 16)
	v.add_child(_tracker_title)

	_tracker_desc = Label.new()
	_tracker_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tracker_desc.custom_minimum_size = Vector2(276, 0)
	_tracker_desc.add_theme_color_override("font_color", UIStyle.MUTED)
	_tracker_desc.add_theme_font_size_override("font_size", 13)
	v.add_child(_tracker_desc)

	_tracker_stars = Label.new()
	_tracker_stars.add_theme_color_override("font_color", UIStyle.YELLOW)
	_tracker_stars.add_theme_font_size_override("font_size", 18)
	v.add_child(_tracker_stars)


func _update_tracker() -> void:
	var m := Progress.current_mission
	_tracker.visible = m != null
	if m == null:
		return
	_tracker_title.text = "Missão: %s%s" % [m.title, "  ✓" if Progress.completed else ""]
	_tracker_desc.text = m.description
	_tracker_stars.text = "★ %d / %d" % [Progress.stars.size(), Progress.total_stars()]


# ------------------------------------------------------------------ balão rápido (rodapé)
func _build_toast() -> void:
	# Contêiner de tela cheia que empurra o balão para o rodapé, centralizado
	var wrapper := MarginContainer.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_theme_constant_override("margin_bottom", 32)
	add_child(wrapper)
	wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(column)

	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.YELLOW, 3, 6, 14))
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_toast.modulate.a = 0.0
	column.add_child(_toast)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_toast.add_child(v)

	_toast_title = Label.new()
	UIStyle.style_title(_toast_title, 18)
	v.add_child(_toast_title)

	_toast_desc = Label.new()
	_toast_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_desc.custom_minimum_size = Vector2(490, 0)
	_toast_desc.add_theme_color_override("font_color", UIStyle.TEXT)
	v.add_child(_toast_desc)


func _show_toast(title: String, desc: String, seconds: float = 3.5) -> void:
	_toast_title.text = title
	_toast_desc.text = desc
	if _toast_tween != null:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


# ------------------------------------------------------------------ balão de missão cumprida
func _build_popup() -> void:
	_popup = Control.new()
	_popup.visible = false
	add_child(_popup)
	_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	_popup.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_popup.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.YELLOW, 3, 6, 28))
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var title := Label.new()
	title.text = "MISSÃO CUMPRIDA!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyle.style_title(title, 26)
	v.add_child(title)

	_popup_mission = Label.new()
	_popup_mission.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_mission.add_theme_color_override("font_color", UIStyle.YELLOW)
	v.add_child(_popup_mission)

	_popup_text = Label.new()
	_popup_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_text.custom_minimum_size = Vector2(480, 0)
	_popup_text.add_theme_color_override("font_color", UIStyle.TEXT)
	v.add_child(_popup_text)

	_popup_stars = Label.new()
	_popup_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_stars.add_theme_color_override("font_color", UIStyle.YELLOW)
	_popup_stars.add_theme_font_size_override("font_size", 22)
	v.add_child(_popup_stars)

	var hint := Label.new()
	hint.text = "Existem outros jeitos de cumprir a missão. Continue explorando para ganhar mais estrelas!"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(480, 0)
	hint.add_theme_color_override("font_color", UIStyle.MUTED)
	hint.add_theme_font_size_override("font_size", 14)
	v.add_child(hint)

	_popup_next = Button.new()
	_popup_next.text = "Próxima fase"
	_popup_next.custom_minimum_size = Vector2(0, 48)
	_popup_next.visible = false
	UIStyle.style_button(_popup_next, UIStyle.YELLOW, UIStyle.DARK)
	_popup_next.pressed.connect(_on_popup_next)
	v.add_child(_popup_next)

	var button := Button.new()
	button.text = "Continuar explorando"
	button.custom_minimum_size = Vector2(0, 48)
	UIStyle.style_button(button, UIStyle.CELL, UIStyle.TEXT)
	button.pressed.connect(_on_popup_close)
	v.add_child(button)


func _on_popup_close() -> void:
	_popup.visible = false


func _on_popup_next() -> void:
	_popup.visible = false
	get_tree().paused = false
	if _next_scene != "":
		get_tree().change_scene_to_file(_next_scene)


# ------------------------------------------------------------------ reações aos eventos
func _on_element_collected(id: String) -> void:
	var e := Database.get_element(id)
	if e == null:
		return
	_show_toast("%s (%s) · nº %d" % [e.display_name, e.symbol, e.atomic_number], e.description)


func _on_mission_started(mission: MissionData) -> void:
	_update_tracker()
	if mission != null and mission.show_tutorial and not Progress.tutorial_done:
		_tutorial.start()


func _on_hint_requested() -> void:
	_tutorial.notify_event("hint")


func _on_star_earned(recipe: RecipeData, stars: int, total: int) -> void:
	_update_tracker()
	if stars > 1:   # a primeira estrela é anunciada pelo balão de missão cumprida
		var title := "★ Nova estrela! %d / %d" % [stars, total]
		if stars == total:
			title = "★ Todas as estrelas conquistadas! %d / %d" % [stars, total]
		_show_toast(title, "%s (%s): %s" % [recipe.result_name, UIStyle.formula(recipe.result_formula), recipe.explanation], 5.0)


func _on_mission_completed(mission: MissionData, recipe: RecipeData) -> void:
	_update_tracker()
	_popup_mission.text = mission.title
	_popup_text.text = "%s (%s)\n%s" % [recipe.result_name, UIStyle.formula(recipe.result_formula), recipe.explanation]
	_popup_stars.text = "★ %d / %d" % [Progress.stars.size(), Progress.total_stars()]
	_next_scene = mission.next_scene
	_popup_next.visible = _next_scene != ""
	_popup.visible = true


# ------------------------------------------------------------------ menu de pausa (Esc)
func _build_pause() -> void:
	_pause = Control.new()
	_pause.visible = false
	add_child(_pause)
	_pause.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	_pause.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_pause.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.YELLOW, 3, 6, 28))
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(300, 0)
	panel.add_child(v)

	var title := Label.new()
	title.text = "PAUSADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyle.style_title(title, 26)
	v.add_child(title)

	var resume := Button.new()
	resume.text = "Continuar"
	resume.custom_minimum_size = Vector2(0, 48)
	UIStyle.style_button(resume, UIStyle.YELLOW, UIStyle.DARK)
	resume.pressed.connect(_on_pause_resume)
	v.add_child(resume)

	var restart := Button.new()
	restart.text = "Reiniciar fase"
	restart.custom_minimum_size = Vector2(0, 48)
	UIStyle.style_button(restart, UIStyle.CELL, UIStyle.TEXT)
	restart.pressed.connect(_on_pause_restart)
	v.add_child(restart)

	var menu := Button.new()
	menu.text = "Voltar ao menu"
	menu.custom_minimum_size = Vector2(0, 48)
	UIStyle.style_button(menu, UIStyle.CELL, UIStyle.TEXT)
	menu.pressed.connect(_on_pause_menu)
	v.add_child(menu)

	var quit := Button.new()
	quit.text = "Sair do jogo"
	quit.custom_minimum_size = Vector2(0, 48)
	UIStyle.style_button(quit, UIStyle.CELL, UIStyle.TEXT)
	quit.pressed.connect(_on_pause_quit)
	v.add_child(quit)


func _set_pause_open(open: bool) -> void:
	_pause.visible = open
	get_tree().paused = open


func _on_pause_resume() -> void:
	_set_pause_open(false)


func _on_pause_restart() -> void:
	# Recomeça a fase do zero (elementos coletados e receitas). As estrelas continuam salvas.
	if Progress.current_mission != null:
		Progress.reset_level_state(Progress.current_mission.id)
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_pause_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main/main.tscn")


func _on_pause_quit() -> void:
	get_tree().quit()

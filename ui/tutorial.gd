class_name Tutorial
extends Control
## Tutorial interativo da primeira vez: cada passo espera o jogador fazer a ação pedida.
## O progresso é salvo (Progress.tutorial_done), então só aparece uma vez.

signal finished

const STEPS := [
	{"event": "move", "text": "Use A e D (ou as setas) para andar."},
	{"event": "sprint", "text": "Segure Shift enquanto anda para correr."},
	{"event": "jump", "text": "Aperte Espaço (ou W) para pular."},
	{"event": "collected", "text": "Toque em um bloco amarelo para coletar um elemento químico."},
	{"event": "inventory", "text": "Aperte I ou Tab para abrir o inventário e ver a tabela periódica."},
	{"event": "hint", "text": "Não sabe o que fazer? Clique no botão Dica do painel Combinar. Cada clique dá uma pista maior."},
	{"event": "combined", "text": "Para formar água, colete 2 hidrogênios (H) e 1 oxigênio (O). No inventário, clique em H duas vezes, em O uma vez e aperte Combinar."},
]

var _index: int = -1
var _active: bool = false
var _seen: Dictionary = {}
var _title: Label
var _text: Label
var _dots: Label
var _skip: Button


func _ready() -> void:
	GameInput.ensure_actions()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false
	set_process(false)
	Inventory.element_collected.connect(_on_collected)
	Inventory.compound_formed.connect(_on_compound)


func start() -> void:
	if _active:
		return
	_active = true
	_index = -1
	_seen.clear()
	visible = true
	_skip.visible = true
	set_process(true)
	_next_step()


## Avisa o tutorial de que algo aconteceu (usado pelo HUD e pelo inventário).
func notify_event(event: String) -> void:
	if not _active:
		return
	_seen[event] = true
	if _index >= 0 and _index < STEPS.size() and STEPS[_index]["event"] == event:
		_next_step()


func _process(_delta: float) -> void:
	if get_tree().paused:
		return
	if absf(Input.get_axis("esquerda", "direita")) > 0.1:
		notify_event("move")
		if Input.is_action_pressed("correr"):
			notify_event("sprint")
	if Input.is_action_just_pressed("pular"):
		notify_event("jump")


func _on_collected(_id: String) -> void:
	notify_event("collected")


func _on_compound(_recipe_id: String) -> void:
	notify_event("combined")


func _next_step() -> void:
	_index += 1
	# passos cuja ação o jogador já fez antes são pulados
	while _index < STEPS.size() and _seen.has(STEPS[_index]["event"]):
		_index += 1
	if _index >= STEPS.size():
		_complete()
	else:
		_show_step()


func _show_step() -> void:
	_title.text = "TUTORIAL · Passo %d de %d" % [_index + 1, STEPS.size()]
	_text.text = STEPS[_index]["text"]
	var marks: Array[String] = []
	for i in STEPS.size():
		marks.append("●" if i <= _index else "○")
	_dots.text = " ".join(marks)


func _complete() -> void:
	_active = false
	set_process(false)
	_title.text = "TUTORIAL CONCLUÍDO"
	_text.text = "Muito bem! Agora é com você: descubra os outros compostos da missão para ganhar mais estrelas."
	_dots.text = ""
	_skip.visible = false
	Progress.finish_tutorial()
	finished.emit()
	var tween := create_tween()
	tween.tween_interval(5.0)
	tween.tween_callback(_hide)


func _hide() -> void:
	visible = false


func _on_skip() -> void:
	_active = false
	set_process(false)
	visible = false
	Progress.finish_tutorial()
	finished.emit()


func _build() -> void:
	# Cartão no topo e centralizado horizontalmente
	var wrapper := MarginContainer.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_theme_constant_override("margin_top", 24)
	wrapper.add_theme_constant_override("margin_left", 24)
	wrapper.add_theme_constant_override("margin_right", 24)
	add_child(wrapper)
	wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(column)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.YELLOW, 3, 6, 14))
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.custom_minimum_size = Vector2(430, 0)
	column.add_child(card)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)

	var header := HBoxContainer.new()
	v.add_child(header)

	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIStyle.style_title(_title, 15)
	_title.add_theme_color_override("font_color", UIStyle.YELLOW)
	header.add_child(_title)

	_skip = Button.new()
	_skip.text = "Pular"
	UIStyle.style_button(_skip, UIStyle.CELL, UIStyle.TEXT, 13)
	_skip.pressed.connect(_on_skip)
	header.add_child(_skip)

	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(400, 0)
	_text.add_theme_color_override("font_color", UIStyle.TEXT)
	v.add_child(_text)

	_dots = Label.new()
	_dots.add_theme_color_override("font_color", UIStyle.MUTED)
	_dots.add_theme_font_size_override("font_size", 13)
	v.add_child(_dots)

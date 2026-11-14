class_name SettingsPanel
extends PanelContainer
## Painel de configurações: volume geral e tela cheia. As escolhas ficam salvas em user://settings.cfg.

signal closed

const PATH := "user://settings.cfg"

var _slider: HSlider
var _percent: Label
var _fullscreen: CheckButton
var _confirm_erase: bool = false


## Aplica as configurações salvas (chame uma vez ao abrir o jogo).
static func apply_saved() -> void:
	var volume := 1.0
	var fullscreen := false
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		volume = float(cfg.get_value("audio", "volume", 1.0))
		fullscreen = bool(cfg.get_value("video", "fullscreen", false))
	_apply(volume, fullscreen)


static func _apply(volume: float, fullscreen: bool) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus, volume <= 0.001)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.YELLOW, 3, 6, 28))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.custom_minimum_size = Vector2(380, 0)
	add_child(v)

	var title := Label.new()
	title.text = "CONFIGURAÇÕES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyle.style_title(title, 26)
	v.add_child(title)

	var vol_label := Label.new()
	vol_label.text = "Volume geral"
	vol_label.add_theme_color_override("font_color", UIStyle.TEXT)
	v.add_child(vol_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)

	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.05
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.custom_minimum_size = Vector2(0, 28)
	row.add_child(_slider)

	_percent = Label.new()
	_percent.custom_minimum_size = Vector2(52, 0)
	_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_percent.add_theme_color_override("font_color", UIStyle.YELLOW)
	row.add_child(_percent)

	_fullscreen = CheckButton.new()
	_fullscreen.text = "Tela cheia"
	_fullscreen.add_theme_color_override("font_color", UIStyle.TEXT)
	v.add_child(_fullscreen)

	var tutorial := Button.new()
	tutorial.text = "Rever tutorial na próxima partida"
	tutorial.custom_minimum_size = Vector2(0, 40)
	UIStyle.style_button(tutorial, UIStyle.CELL, UIStyle.TEXT, 14)
	tutorial.pressed.connect(_on_replay_tutorial.bind(tutorial))
	v.add_child(tutorial)

	var erase := Button.new()
	erase.text = "Apagar progresso e tutorial"
	erase.custom_minimum_size = Vector2(0, 40)
	UIStyle.style_button(erase, UIStyle.CELL, UIStyle.TEXT, 14)
	erase.pressed.connect(_on_erase.bind(erase))
	v.add_child(erase)

	var back := Button.new()
	back.text = "Voltar"
	back.custom_minimum_size = Vector2(0, 48)
	UIStyle.style_button(back, UIStyle.YELLOW, UIStyle.DARK)
	back.pressed.connect(func() -> void: closed.emit())
	v.add_child(back)

	_load_into_controls()
	_slider.value_changed.connect(_on_changed)
	_fullscreen.toggled.connect(_on_changed)


func _load_into_controls() -> void:
	var cfg := ConfigFile.new()
	var volume := 1.0
	var fullscreen := false
	if cfg.load(PATH) == OK:
		volume = float(cfg.get_value("audio", "volume", 1.0))
		fullscreen = bool(cfg.get_value("video", "fullscreen", false))
	_slider.set_value_no_signal(volume)
	_fullscreen.set_pressed_no_signal(fullscreen)
	_percent.text = "%d%%" % int(round(volume * 100.0))


func _on_changed(_value = null) -> void:
	var volume := float(_slider.value)
	var fullscreen := _fullscreen.button_pressed
	_percent.text = "%d%%" % int(round(volume * 100.0))
	_apply(volume, fullscreen)
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)


func _on_erase(button: Button) -> void:
	if not _confirm_erase:
		_confirm_erase = true
		button.text = "Clique de novo para confirmar"
		return
	_confirm_erase = false
	button.text = "Apagar progresso e tutorial"
	Progress.erase_saved()


func _on_replay_tutorial(button: Button) -> void:
	Progress.reset_tutorial()
	button.text = "Tutorial será mostrado de novo"

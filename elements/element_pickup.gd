extends Area2D
## Elemento coletável no mundo. Escolha qual é pelo Inspector (element_id).
## A aparência (bloco arredondado com brilho pulsante) é desenhada aqui.

@export var element_id: String = "h"
@export var amount: int = 1

@onready var _label: Label = $Label

var _collected: bool = false
var _time: float = 0.0
var _style := StyleBoxFlat.new()


func _ready() -> void:
	add_to_group("pickups")
	var data := Database.get_element(element_id)
	if data == null:
		push_warning("ElementPickup: elemento '%s' não existe no banco." % element_id)
		_label.text = "?"
	else:
		_label.text = data.symbol
	body_entered.connect(_on_body_entered)

	# Esconde o quadrado simples antigo, se existir
	var old_visual := get_node_or_null("Visual") as CanvasItem
	if old_visual != null:
		old_visual.visible = false

	_style.bg_color = Color(0.957, 0.784, 0.298)
	_style.border_color = Color(1.0, 0.93, 0.62)
	_style.set_border_width_all(2)
	_style.set_corner_radius_all(7)
	_style.shadow_color = Color(0, 0, 0, 0.25)
	_style.shadow_size = 4
	_style.shadow_offset = Vector2(0, 3)

	# Flutuação leve para chamar atenção
	var base_y := position.y
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", base_y - 6.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", base_y + 6.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	draw_circle(Vector2.ZERO, 32.0 + pulse * 4.0, Color(0.957, 0.784, 0.298, 0.07 + pulse * 0.05))
	draw_circle(Vector2.ZERO, 25.0, Color(0.957, 0.784, 0.298, 0.12))
	draw_style_box(_style, Rect2(-18.0, -18.0, 36.0, 36.0))


func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	set_deferred("monitoring", false)
	Progress.record_pickup(String(name))   # lembra que este bloco já foi coletado
	Inventory.add_element(element_id, amount)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)

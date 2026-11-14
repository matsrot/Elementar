extends Node2D
## Aparência do jogador: um(a) cientista de jaleco, desenhado(a) por código,
## com animação de andar, correr (inclina o corpo) e pular.

const SKIN := Color(0.96, 0.78, 0.62)
const HAIR := Color(0.22, 0.14, 0.10)
const COAT := Color(0.95, 0.96, 0.98)
const COAT_SHADE := Color(0.76, 0.80, 0.87)
const SHIRT := Color(0.15, 0.35, 0.65)
const PANTS := Color(0.20, 0.24, 0.32)
const SHOE := Color(0.10, 0.10, 0.12)
const GLASS := Color(0.15, 0.20, 0.30)

const LEG_LENGTH := 15.0
const ARM_LENGTH := 13.0

var _body: CharacterBody2D
var _phase: float = 0.0
var _time: float = 0.0
var _facing: float = 1.0


func _ready() -> void:
	_body = get_parent() as CharacterBody2D


func _process(delta: float) -> void:
	if _body == null:
		return
	_time += delta
	var vx := _body.velocity.x
	if vx > 5.0:
		_facing = 1.0
	elif vx < -5.0:
		_facing = -1.0
	if _body.is_on_floor():
		if absf(vx) > 5.0:
			_phase += delta * (16.0 if bool(_body.get("running")) else 10.0)
		else:
			_phase = 0.0
	queue_redraw()


func _draw() -> void:
	if _body == null:
		return
	var on_floor := _body.is_on_floor()
	var moving := on_floor and absf(_body.velocity.x) > 5.0
	var running := bool(_body.get("running"))

	var swing := 0.0
	if moving:
		swing = sin(_phase) * (0.95 if running else 0.7)
	var bob := 0.0
	if moving:
		bob = -absf(sin(_phase)) * 1.5
	elif on_floor:
		bob = sin(_time * 2.0) * 0.5
	var lean := 0.16 if (moving and running) else 0.0

	# Espelha conforme a direção e inclina o corpo ao correr
	draw_set_transform(Vector2(0, bob + 1.0), lean * _facing, Vector2(_facing, 1.0))

	# Ângulos dos membros (no ar: pose de salto)
	var leg_front := swing
	var leg_back := -swing
	var arm_front := -swing
	var arm_back := swing
	if not on_floor:
		if _body.velocity.y < 0.0:   # subindo
			leg_front = 0.75
			leg_back = -0.35
			arm_front = -2.5
			arm_back = -2.0
		else:                        # caindo
			leg_front = 0.25
			leg_back = -0.15
			arm_front = -1.7
			arm_back = -1.3

	var hip := Vector2(0, 8)
	var shoulder := Vector2(0, -8)

	# Atrás do corpo: perna e braço de trás
	_draw_leg(hip, leg_back)
	_draw_arm(shoulder, arm_back, COAT_SHADE)

	# Jaleco e camisa
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -12), Vector2(8, -12), Vector2(9.5, 12), Vector2(-9.5, 12)]), COAT)
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -12), Vector2(3, -12), Vector2(0, -4)]), SHIRT)
	draw_line(Vector2(0, -4), Vector2(0, 12), COAT_SHADE, 1.5)
	draw_line(Vector2(-9.5, 12), Vector2(9.5, 12), COAT_SHADE, 2.0)

	# Frente: perna e braço da frente
	_draw_leg(hip, leg_front)
	_draw_arm(shoulder, arm_front, COAT)

	# Cabeça, cabelo e óculos
	var head := Vector2(0, -19)
	draw_circle(head, 7.5, SKIN)
	draw_arc(head, 6.6, PI, TAU, 14, HAIR, 5.0)
	var eye := head + Vector2(3.5, -0.5)
	draw_circle(eye, 1.2, GLASS)
	draw_arc(eye, 3.0, 0.0, TAU, 14, GLASS, 1.2)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_leg(hip: Vector2, angle: float) -> void:
	var foot := hip + Vector2(sin(angle), cos(angle)) * LEG_LENGTH
	draw_line(hip, foot, PANTS, 6.0, true)
	draw_line(foot + Vector2(-1, 0), foot + Vector2(5, 0), SHOE, 5.0, true)


func _draw_arm(shoulder: Vector2, angle: float, color: Color) -> void:
	var hand := shoulder + Vector2(sin(angle), cos(angle)) * ARM_LENGTH
	draw_line(shoulder, hand, color, 5.0, true)
	draw_circle(hand, 3.0, SKIN)

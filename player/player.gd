extends CharacterBody2D
## Jogador: movimento lateral com pulo (coyote time e jump buffer) e corrida com Shift.

@export var speed: float = 260.0
@export var run_speed: float = 400.0        ## velocidade ao segurar Shift
@export var jump_velocity: float = -520.0
@export var gravity: float = 1400.0
@export var coyote_time: float = 0.1        ## tempo extra para pular após sair da borda
@export var jump_buffer_time: float = 0.1   ## tempo em que um pulo antecipado é lembrado

var running: bool = false                   ## lido pela animação (player_visual.gd)
var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0


func _ready() -> void:
	GameInput.ensure_actions()


func _physics_process(delta: float) -> void:
	# Gravidade e coyote time
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta
		velocity.y += gravity * delta

	# Jump buffer
	if Input.is_action_just_pressed("pular"):
		_buffer_timer = jump_buffer_time
	else:
		_buffer_timer -= delta

	# Pulo
	if _buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		GameAudio.play_sfx("pulo")
		_buffer_timer = 0.0
		_coyote_timer = 0.0

	# Soltar o botão cedo = pulo mais baixo
	if Input.is_action_just_released("pular") and velocity.y < 0.0:
		velocity.y *= 0.5

	# Movimento horizontal (Shift = correr)
	var direction := Input.get_axis("esquerda", "direita")
	running = direction != 0.0 and Input.is_action_pressed("correr")
	velocity.x = direction * (run_speed if running else speed)

	move_and_slide()

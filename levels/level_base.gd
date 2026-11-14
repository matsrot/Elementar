extends Node2D
## Script base de uma fase: começa a missão, restaura o progresso salvo (elementos já
## coletados) e limita a câmera às paredes e ao chão da fase.

@export var mission: MissionData
@export var auto_camera_limits: bool = true   ## calcula os limites da câmera pelas paredes/chão


func _ready() -> void:
	Progress.begin_level(mission, self)
	GameAudio.play_music("musica_fase")
	if auto_camera_limits:
		_apply_camera_limits()


## A câmera não mostra nada além das bordas externas dos corpos estáticos (paredes, chão, plataformas)
## nem dos TileMapLayer com colisão. Se a fase ficar com alguma borda errada, desligue
## auto_camera_limits no Inspector e ajuste os limites direto no Camera2D do jogador.
func _apply_camera_limits() -> void:
	var camera := get_node_or_null("Player/Camera2D") as Camera2D
	if camera == null:
		camera = get_viewport().get_camera_2d()
	if camera == null:
		return
	var bounds := _level_bounds()
	if bounds.size == Vector2.ZERO:
		return
	var view_h := get_viewport_rect().size.y
	camera.limit_left = int(floor(bounds.position.x))
	camera.limit_right = int(ceil(bounds.end.x))
	camera.limit_bottom = int(ceil(bounds.end.y))
	camera.limit_top = int(floor(minf(bounds.position.y, bounds.end.y - view_h)))


func _level_bounds() -> Rect2:
	var bounds := Rect2()
	var found := false
	for node in _descendants(self):
		var r := Rect2()
		var has := false
		if node is CollisionShape2D and node.get_parent() is StaticBody2D:
			var cs := node as CollisionShape2D
			if cs.shape is RectangleShape2D:
				var size := (cs.shape as RectangleShape2D).size
				r = cs.global_transform * Rect2(-size / 2.0, size)
				has = true
		elif node is TileMapLayer:
			var layer := node as TileMapLayer
			var used := layer.get_used_rect()
			if used.size != Vector2i.ZERO and layer.tile_set != null and layer.tile_set.get_physics_layers_count() > 0:
				var ts := Vector2(layer.tile_set.tile_size)
				r = layer.global_transform * Rect2(Vector2(used.position) * ts, Vector2(used.size) * ts)
				has = true
		if has:
			bounds = r if not found else bounds.merge(r)
			found = true
	return bounds if found else Rect2()


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_descendants(child))
	return out

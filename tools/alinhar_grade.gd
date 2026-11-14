@tool
extends EditorScript
## Alinha à grade as plataformas/paredes (StaticBody2D) e os elementos coletáveis da fase aberta no editor.
##
## COMO USAR
##  1. Salve uma cópia da fase (esta ação não tem "desfazer").
##  2. Abra a cena da fase no editor (ex.: levels/test_level.tscn).
##  3. Abra ESTE arquivo no editor de scripts e use Arquivo > Executar (Ctrl+Shift+X).
##  4. Confira o resultado no painel "Saída" e salve a cena (Ctrl+S).
##
## A grade é o tamanho do tile do primeiro TileMapLayer da fase; se não houver, usa DEFAULT_GRID.
## Plataformas e paredes: o canto superior esquerdo vai para o cruzamento mais próximo da grade.
## Elementos coletáveis: o centro vai para o centro da célula mais próxima.

const DEFAULT_GRID := Vector2(40, 40)


func _run() -> void:
	var root := get_scene()
	if root == null:
		push_error("Abra a cena da fase antes de executar este script.")
		return

	var nodes := _descendants(root)
	var grid := _detect_grid(nodes)
	var moved_bodies := 0
	var moved_pickups := 0
	for node in nodes:
		if node is StaticBody2D:
			if _snap_body(node as StaticBody2D, grid):
				moved_bodies += 1
		elif node is Area2D and node.scene_file_path.ends_with("element_pickup.tscn"):
			if _snap_pickup(node as Area2D, grid):
				moved_pickups += 1

	print("Alinhar à grade (%d x %d px): %d plataformas/paredes e %d elementos ajustados." % [grid.x, grid.y, moved_bodies, moved_pickups])
	if moved_bodies + moved_pickups > 0:
		EditorInterface.mark_scene_as_unsaved()
		print("Salve a cena (Ctrl+S) para manter as mudanças.")


func _detect_grid(nodes: Array[Node]) -> Vector2:
	for node in nodes:
		if node is TileMapLayer and (node as TileMapLayer).tile_set != null:
			return Vector2((node as TileMapLayer).tile_set.tile_size)
	return DEFAULT_GRID


func _snap_body(body: StaticBody2D, grid: Vector2) -> bool:
	for child in body.get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			var cs := child as CollisionShape2D
			var size := (cs.shape as RectangleShape2D).size * cs.global_scale.abs()
			var top_left := cs.global_position - size / 2.0
			var snapped_pos := (top_left / grid).round() * grid
			var delta := snapped_pos - top_left
			if delta.length() < 0.01:
				return false
			body.global_position += delta
			return true
	return false


func _snap_pickup(pickup: Area2D, grid: Vector2) -> bool:
	var cell := (pickup.global_position / grid).floor()
	var target := (cell + Vector2(0.5, 0.5)) * grid
	if pickup.global_position.distance_to(target) < 0.01:
		return false
	pickup.global_position = target
	return true


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_descendants(child))
	return out

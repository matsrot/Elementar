extends Node
## Inventário do jogador (autoload "Inventory"):
## elementos que ele tem, compostos que já formou e receitas descobertas.

signal changed
signal element_collected(id: String)
signal compound_formed(recipe_id: String)

var items: Dictionary = {}        # id do elemento -> quantidade
var compounds: Dictionary = {}    # id da receita -> quantidade do composto formado
var discovered: Dictionary = {}   # id da receita -> true


## announce = false evita mostrar o balão (usado ao separar um composto).
func add_element(id: String, amount: int = 1, announce: bool = true) -> void:
	if Database.get_element(id) == null:
		push_warning("Inventory: elemento desconhecido '%s'" % id)
		return
	items[id] = count_of(id) + amount
	changed.emit()
	if announce:
		element_collected.emit(id)


func remove_element(id: String, amount: int = 1) -> bool:
	if count_of(id) < amount:
		return false
	items[id] = count_of(id) - amount
	if items[id] <= 0:
		items.erase(id)
	changed.emit()
	return true


func count_of(id: String) -> int:
	return int(items.get(id, 0))


func has_element(id: String) -> bool:
	return count_of(id) > 0


# ---- compostos (resultado das receitas) ----
func add_compound(recipe_id: String, amount: int = 1) -> void:
	compounds[recipe_id] = compound_count(recipe_id) + amount
	changed.emit()
	compound_formed.emit(recipe_id)


func remove_compound(recipe_id: String, amount: int = 1) -> bool:
	if compound_count(recipe_id) < amount:
		return false
	compounds[recipe_id] = compound_count(recipe_id) - amount
	if compounds[recipe_id] <= 0:
		compounds.erase(recipe_id)
	changed.emit()
	return true


func compound_count(recipe_id: String) -> int:
	return int(compounds.get(recipe_id, 0))


# ---- receitas descobertas ----
func discover_recipe(recipe_id: String) -> void:
	if not discovered.has(recipe_id):
		discovered[recipe_id] = true
		changed.emit()


func is_discovered(recipe_id: String) -> bool:
	return discovered.has(recipe_id)


func reset() -> void:
	items.clear()
	compounds.clear()
	discovered.clear()
	changed.emit()

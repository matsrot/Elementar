extends Node
## Progresso (autoload "Progress"): missão atual, estrelas da partida e estrelas salvas por fase.
## Cada método diferente (receita da missão) vale uma estrela. Sem punição, só incentivo.

signal mission_started(mission: MissionData)
signal star_earned(recipe: RecipeData, stars: int, total: int)
signal mission_completed(mission: MissionData, recipe: RecipeData)

const SAVE_PATH := "user://progress.cfg"

var current_mission: MissionData = null
var stars: Dictionary = {}        # method_id -> true (partida atual)
var completed: bool = false
var tutorial_done: bool = false   # tutorial da primeira vez já concluído/pulado (salvo em disco)
var level_state: Dictionary = {}   # id da missão -> {pickups, items, compounds, recipes} (progresso da fase, salvo em disco)
var _restoring: bool = false
var best: Dictionary = {}         # id da missão -> {method_id: true} (estrelas já conquistadas, salvas em disco)


func _ready() -> void:
	_load()
	Inventory.compound_formed.connect(_on_compound_formed)
	Inventory.changed.connect(_on_inventory_changed)


## Chamado pela fase ao começar: zera o inventário, inicia a missão e restaura o que já estava salvo
## (elementos já coletados somem do cenário e voltam ao inventário).
func begin_level(mission: MissionData, level: Node) -> void:
	_restoring = true
	Inventory.reset()
	start_mission(mission)
	_restore_level_state(mission, level)
	_restoring = false


## Registra um elemento coletado do cenário (pelo nome do nó).
func record_pickup(pickup_name: String) -> void:
	if current_mission == null or current_mission.id.is_empty():
		return
	var st := _state_for(current_mission.id)
	var picked: Array = st["pickups"]
	if not picked.has(pickup_name):
		picked.append(pickup_name)


## Esquece o que foi coletado/combinado numa fase (as estrelas continuam salvas).
func reset_level_state(mission_id: String) -> void:
	level_state.erase(mission_id)
	_save()


func _state_for(mission_id: String) -> Dictionary:
	if not level_state.has(mission_id):
		level_state[mission_id] = {"pickups": [], "items": {}, "compounds": {}, "recipes": []}
	return level_state[mission_id]


func _restore_level_state(mission: MissionData, level: Node) -> void:
	if mission == null or mission.id.is_empty() or not level_state.has(mission.id):
		return
	var st: Dictionary = level_state[mission.id]
	var picked: Array = st["pickups"]
	for node in level.get_children():
		if node.is_in_group("pickups") and picked.has(String(node.name)):
			node.queue_free()
	Inventory.items = (st["items"] as Dictionary).duplicate()
	Inventory.compounds = (st["compounds"] as Dictionary).duplicate()
	Inventory.discovered = {}
	for recipe_id in st["recipes"]:
		Inventory.discovered[recipe_id] = true
	Inventory.changed.emit()


func _on_inventory_changed() -> void:
	if _restoring or current_mission == null or current_mission.id.is_empty():
		return
	var st := _state_for(current_mission.id)
	st["items"] = Inventory.items.duplicate()
	st["compounds"] = Inventory.compounds.duplicate()
	st["recipes"] = Inventory.discovered.keys()
	_save()


func start_mission(mission: MissionData) -> void:
	current_mission = mission
	stars.clear()
	# Recupera as estrelas já conquistadas nesta missão (salvas em disco)
	if mission != null and best.has(mission.id):
		var valid := _valid_methods(mission)
		var saved: Dictionary = best[mission.id]
		for method_id in saved:
			if valid.has(method_id):
				stars[method_id] = true
	# Se já tinha estrela, a missão já foi cumprida antes: não repete o balão de "missão cumprida"
	completed = not stars.is_empty()
	mission_started.emit(mission)


## Métodos (method_id) que valem estrela em uma missão.
func _valid_methods(mission: MissionData) -> Dictionary:
	var valid: Dictionary = {}
	for recipe in Database.recipes:
		var counts: bool = recipe.category == mission.required_category
		if not mission.recipe_ids.is_empty():
			counts = mission.recipe_ids.has(recipe.id)
		if counts:
			valid[recipe.method_id] = true
	return valid


## Quantas estrelas existem na missão atual.
func total_stars() -> int:
	return total_for(current_mission)


## Quantas estrelas existem em uma missão (uma por receita da lista ou da categoria exigida).
func total_for(mission: MissionData) -> int:
	if mission == null:
		return 0
	if not mission.recipe_ids.is_empty():
		return mission.recipe_ids.size()
	var n := 0
	for recipe in Database.recipes:
		if recipe.category == mission.required_category:
			n += 1
	return n


## Estrelas já conquistadas (e salvas) em uma missão.
func saved_stars(mission_id: String) -> int:
	var d: Dictionary = best.get(mission_id, {})
	return d.size()


func finish_tutorial() -> void:
	tutorial_done = true
	_save()


func reset_tutorial() -> void:
	tutorial_done = false
	_save()


func erase_saved() -> void:
	best.clear()
	level_state.clear()
	tutorial_done = false
	var real_path := ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(real_path)


func _counts_for_mission(recipe: RecipeData) -> bool:
	if not current_mission.recipe_ids.is_empty():
		return current_mission.recipe_ids.has(recipe.id)
	return recipe.category == current_mission.required_category


func _on_compound_formed(recipe_id: String) -> void:
	if current_mission == null:
		return
	var recipe := Database.get_recipe(recipe_id)
	if recipe == null or not _counts_for_mission(recipe):
		return
	if stars.has(recipe.method_id):
		return   # método já descoberto: não ganha estrela de novo
	stars[recipe.method_id] = true
	_remember(recipe.method_id)
	star_earned.emit(recipe, stars.size(), total_stars())
	if not completed:
		completed = true
		mission_completed.emit(current_mission, recipe)


func _remember(method_id: String) -> void:
	var mission_id := current_mission.id
	if mission_id.is_empty():
		return
	if not best.has(mission_id):
		best[mission_id] = {}
	best[mission_id][method_id] = true
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	for mission_id in best:
		cfg.set_value("stars", str(mission_id), PackedStringArray(best[mission_id].keys()))
	cfg.set_value("meta", "tutorial_done", tutorial_done)
	for mission_id in level_state:
		var st: Dictionary = level_state[mission_id]
		var section := "level_%s" % mission_id
		cfg.set_value(section, "pickups", PackedStringArray(st["pickups"]))
		cfg.set_value(section, "items", st["items"])
		cfg.set_value(section, "compounds", st["compounds"])
		cfg.set_value(section, "recipes", PackedStringArray(st["recipes"]))
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	tutorial_done = bool(cfg.get_value("meta", "tutorial_done", false))
	for mission_id in cfg.get_section_keys("stars"):
		var methods: PackedStringArray = cfg.get_value("stars", mission_id, PackedStringArray())
		var d: Dictionary = {}
		for method_id in methods:
			d[method_id] = true
		best[mission_id] = d

	for section in cfg.get_sections():
		if not section.begins_with("level_"):
			continue
		var mission_id := section.trim_prefix("level_")
		var st := {
			"pickups": Array(cfg.get_value(section, "pickups", PackedStringArray())),
			"items": cfg.get_value(section, "items", {}),
			"compounds": cfg.get_value(section, "compounds", {}),
			"recipes": Array(cfg.get_value(section, "recipes", PackedStringArray())),
		}
		level_state[mission_id] = st

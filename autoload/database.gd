extends Node
## Banco central de elementos e receitas (autoload "Database").
## Carrega tudo de res://data/ na inicialização.

const ELEMENTS_DIR := "res://data/elements/"
const RECIPES_DIR := "res://data/recipes/"
const LEVELS_DIR := "res://data/levels/"

var elements: Dictionary = {}          # id -> ElementData
var recipes: Array[RecipeData] = []
var levels: Array[LevelData] = []      # em ordem de seleção


func _ready() -> void:
	for res in _load_dir(ELEMENTS_DIR):
		var element := res as ElementData
		if element == null:
			continue
		if element.id.is_empty():
			push_warning("Elemento sem id: %s" % element.resource_path)
			continue
		elements[element.id] = element

	for res in _load_dir(RECIPES_DIR):
		var recipe := res as RecipeData
		if recipe != null:
			recipes.append(recipe)

	for res in _load_dir(LEVELS_DIR):
		var level := res as LevelData
		if level != null:
			levels.append(level)
	levels.sort_custom(func(a: LevelData, b: LevelData) -> bool: return a.order < b.order)

	print("[Database] %d elementos, %d receitas e %d fases carregados." % [elements.size(), recipes.size(), levels.size()])


func get_element(id: String) -> ElementData:
	return elements.get(id)


## Procura uma receita cujas entradas sejam exatamente iguais ao dicionário informado.
func find_recipe(inputs: Dictionary) -> RecipeData:
	for recipe in recipes:
		if _same_inputs(recipe.inputs, inputs):
			return recipe
	return null


func get_level(id: String) -> LevelData:
	for level in levels:
		if level.id == id:
			return level
	return null


func get_recipe(id: String) -> RecipeData:
	for recipe in recipes:
		if recipe.id == id:
			return recipe
	return null


func _same_inputs(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for key in a:
		if not b.has(key) or int(a[key]) != int(b[key]):
			return false
	return true


func _load_dir(path: String) -> Array[Resource]:
	var result: Array[Resource] = []
	for file in DirAccess.get_files_at(path):
		# Em builds exportados, os arquivos aparecem com o sufixo ".remap".
		var file_name := file.trim_suffix(".remap")
		if file_name.ends_with(".tres"):
			var res := load(path + file_name)
			if res != null:
				result.append(res)
	return result

class_name RecipeData
extends Resource
## Receita: combinação de elementos que gera um resultado.

@export var id: String = ""
@export var inputs: Dictionary = {}         ## id do elemento -> quantidade (ex.: {"h": 2, "o": 1})
@export var result_name: String = ""        ## ex.: "Água"
@export var result_formula: String = ""     ## ex.: "H2O"
@export_multiline var explanation: String = ""  ## texto do balão informativo
@export var category: String = ""           ## ex.: "oxido" (usado pelas missões)
@export var method_id: String = ""          ## usado pelo sistema de estrelas (um id por método de resolver)

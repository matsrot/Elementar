class_name MissionData
extends Resource
## Missão de uma fase. Cada receita da lista (ou da categoria exigida) vale uma estrela (um "método").

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var recipe_ids: PackedStringArray = PackedStringArray()   ## receitas que valem estrela nesta fase
@export var required_category: String = ""   ## usado só se recipe_ids estiver vazio (ex.: "oxido")
@export_file("*.tscn") var next_scene: String = ""   ## fase seguinte (vazio = última fase)
@export var show_tutorial: bool = false   ## mostra o tutorial interativo na primeira vez

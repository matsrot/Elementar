class_name LevelData
extends Resource
## Dados de uma fase para a tela de seleção: título, descrição, cena e missão.

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export_file("*.tscn") var scene: String = ""
@export var mission: MissionData
@export var order: int = 0            ## posição na lista (menor primeiro)
@export var unlock_level_id: String = ""   ## fase que precisa ter estrelas para liberar esta (vazio = sempre liberada)
@export var unlock_stars: int = 1     ## quantas estrelas são necessárias nessa fase

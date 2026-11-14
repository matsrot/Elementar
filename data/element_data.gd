class_name ElementData
extends Resource
## Dados de um elemento químico. Cada elemento é um arquivo .tres em data/elements/.

@export var id: String = ""                 ## identificador único, minúsculo (ex.: "h")
@export var symbol: String = ""             ## símbolo químico (ex.: "H")
@export var display_name: String = ""       ## nome em português (ex.: "Hidrogênio")
@export var atomic_number: int = 0
@export_range(1, 18) var group: int = 1     ## coluna na tabela periódica (1 a 18)
@export_range(1, 7) var period: int = 1     ## linha na tabela periódica (1 a 7)
@export_multiline var description: String = ""  ## texto curto exibido no balão e no inventário
@export var category: String = ""           ## ex.: "não metal", "metal alcalino"
@export var icon: Texture2D                 ## sprite/ícone (opcional por enquanto)

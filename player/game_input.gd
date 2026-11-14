class_name GameInput
extends RefCounted
## Garante que as ações de entrada extras existam (a ação "correr" fica na tecla Shift),
## sem precisar mexer no Mapa de entrada do projeto.


static func ensure_actions() -> void:
	if not InputMap.has_action("correr"):
		InputMap.add_action("correr")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("correr", ev)

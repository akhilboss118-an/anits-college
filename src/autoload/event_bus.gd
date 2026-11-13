extends Node
## Global signal hub. Scenes never reference each other directly - they emit and
## listen here. This keeps the campus scene unloadable between days and makes
## headless testing possible.

signal mission_step_changed(step: int, total: int, text: String)
signal mission_completed(day: int)
signal dialogue_started(npc_name: String)
signal dialogue_line(text: String)
signal dialogue_ended()
signal energy_changed(value: float)
signal wallet_changed(wallet: int, bank: int)
signal item_gained(item_id: String)
signal drinks_tried_changed(count: int, total: int)
signal boost_changed(seconds_left: float)
signal notification(text: String, seconds: float)
signal call_started()
signal call_ended()
signal gate_state_changed(is_open: bool)
signal player_spawned(position: Vector3)
signal interact_requested()


func notify(text: String, seconds: float = 2.5) -> void:
	notification.emit(text, seconds)

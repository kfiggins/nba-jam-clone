extends Node2D
## Main scene. Wires up HUD, handles match start/restart, and attaches AI controllers.


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p and not p.is_human:
			var controller := AIController.new()
			controller.name = "AIController"
			p.add_child(controller)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		match GameManager.state:
			GameManager.MatchState.PREGAME:
				GameManager.start_match()
			GameManager.MatchState.RESULTS:
				GameManager.restart()

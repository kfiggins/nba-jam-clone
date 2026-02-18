extends Node2D
## Main scene. Wires up HUD and handles match start/restart input.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		match GameManager.state:
			GameManager.MatchState.PREGAME:
				GameManager.start_match()
			GameManager.MatchState.RESULTS:
				GameManager.restart()

extends CanvasLayer
## In-game pause menu overlay. Pauses the game tree when visible.

@onready var panel: Control = $Panel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if panel.visible:
			resume()
		elif GameManager.state == GameManager.MatchState.PLAYING or \
				GameManager.state == GameManager.MatchState.PREGAME:
			show_menu()


func show_menu() -> void:
	panel.visible = true
	get_tree().paused = true


func hide_menu() -> void:
	panel.visible = false


func resume() -> void:
	hide_menu()
	get_tree().paused = false


func _on_resume_pressed() -> void:
	resume()


func _on_restart_pressed() -> void:
	hide_menu()
	get_tree().paused = false
	GameManager.state = GameManager.MatchState.PREGAME
	GameManager.game_state_changed.emit(GameManager.MatchState.RESULTS, GameManager.MatchState.PREGAME)
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	hide_menu()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")

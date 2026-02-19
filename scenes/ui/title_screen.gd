extends Control
## Title screen — shows game name and "Press Enter to Start".


func _ready() -> void:
	# Ensure game is unpaused when returning to title
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_game"):
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")

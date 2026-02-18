class_name PlayerState
extends State
## Base state for player states. Provides typed access to the Player node.

var player: Player


func _ready() -> void:
	if owner is Player:
		player = owner as Player

class_name BallState
extends State
## Base state for ball states. Provides typed access to the Ball node.

var ball: Ball


func _ready() -> void:
	if owner is Ball:
		ball = owner as Ball

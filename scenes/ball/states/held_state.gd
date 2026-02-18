class_name HeldBallState
extends BallState
## Ball is held by a player. Follows owner position with offset.

const HOLD_OFFSET := Vector2(15.0, -5.0)


func enter() -> void:
	ball.ground_velocity = Vector2.ZERO
	ball.height_velocity = 0.0


func physics_process(_delta: float) -> State:
	if ball.current_owner == null:
		return state_machine.get_state("Loose")

	var offset := HOLD_OFFSET
	if ball.current_owner.facing_direction.x != 0.0:
		offset.x *= signf(ball.current_owner.facing_direction.x)
	ball.global_position = ball.current_owner.global_position + offset
	ball.height = ball.current_owner.height + 20.0

	return null

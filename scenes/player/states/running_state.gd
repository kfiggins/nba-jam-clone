class_name RunningState
extends PlayerState
## Player is moving on the ground.


func physics_process(delta: float) -> State:
	player.update_turbo(delta)
	player.apply_movement(delta)

	var dir := player.get_input_direction()
	if dir == Vector2.ZERO and player.velocity.length() < 10.0:
		return state_machine.get_state("Idle")

	if Input.is_action_just_pressed("shoot") and player.is_human:
		return state_machine.get_state("Jumping")

	return null

class_name IdleState
extends PlayerState
## Player is standing still on the ground.


func enter() -> void:
	player.velocity = Vector2.ZERO


func physics_process(delta: float) -> State:
	player.update_turbo(delta)

	var dir := player.get_input_direction()
	if dir != Vector2.ZERO:
		return state_machine.get_state("Running")

	if Input.is_action_just_pressed("shoot") and player.is_human:
		if player.has_ball():
			return state_machine.get_state("Shooting")
		return state_machine.get_state("Jumping")

	if Input.is_action_just_pressed("pass_ball") and player.is_human:
		if player.has_ball():
			player.try_pass()
		else:
			player.try_steal()

	return null

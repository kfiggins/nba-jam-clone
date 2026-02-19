class_name IdleState
extends PlayerState
## Player is standing still on the ground.


func enter() -> void:
	player.velocity = Vector2.ZERO


func physics_process(delta: float) -> State:
	player.update_turbo(delta)

	if not player.has_ball() and player.is_human:
		player.auto_face_ball_handler()

	var dir := player.get_input_direction()
	if dir != Vector2.ZERO:
		return state_machine.get_state("Running")

	if Input.is_action_just_pressed("shoot") and player.is_human:
		if player.has_ball() and not player.is_block_stunned():
			if player.is_in_dunk_range():
				return state_machine.get_state("Dunking")
			return state_machine.get_state("Shooting")
		if not player.has_ball():
			return state_machine.get_state("Jumping")

	if Input.is_action_just_pressed("pass_ball") and player.is_human:
		if player.has_ball():
			player.try_pass()
		else:
			player.try_steal()

	return null

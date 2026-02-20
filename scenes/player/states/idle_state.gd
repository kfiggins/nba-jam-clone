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

	var wants_shoot := player.wants_action("shoot", player.ai_shoot_requested)
	var wants_pass := player.wants_action("pass_ball", player.ai_pass_requested)

	if wants_shoot:
		if player.has_ball() and not player.is_block_stunned():
			if player.is_in_dunk_range():
				return state_machine.get_state("Dunking")
			return state_machine.get_state("Shooting")
		if not player.has_ball():
			return state_machine.get_state("Jumping")

	if wants_pass:
		if player.has_ball():
			player.try_pass()
		elif player.is_human:
			player.wants_pass_from_teammate = true
			player.try_steal()
		else:
			player.try_steal()

	if player.ai_steal_requested and not player.is_human:
		player.try_steal()

	return null

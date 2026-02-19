class_name RunningState
extends PlayerState
## Player is moving on the ground.


func physics_process(delta: float) -> State:
	player.update_turbo(delta)
	player.apply_movement(delta)

	var dir := player.get_input_direction()
	if dir == Vector2.ZERO and player.velocity.length() < GameConfig.data.player_idle_velocity_threshold:
		return state_machine.get_state("Idle")

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
		else:
			player.try_steal()

	if player.ai_steal_requested and not player.is_human:
		player.try_steal()

	return null

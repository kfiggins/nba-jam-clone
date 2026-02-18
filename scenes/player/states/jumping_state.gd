class_name JumpingState
extends PlayerState
## Player is in the air with pseudo-3D height.


func enter() -> void:
	player.apply_jump()


func physics_process(delta: float) -> State:
	player.update_turbo(delta)
	player.apply_gravity(delta)
	player.apply_movement(delta, GameConfig.data.player_air_control)

	if player.is_on_ground():
		var dir := player.get_input_direction()
		if dir != Vector2.ZERO:
			return state_machine.get_state("Running")
		return state_machine.get_state("Idle")

	return null

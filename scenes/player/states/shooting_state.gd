class_name ShootingState
extends PlayerState
## Player is jumping to shoot the ball toward the basket.
## Ball is released after a short delay or at jump apex.

var _shot_released: bool = false
var _release_timer: float = 0.0


func enter() -> void:
	player.apply_jump()
	_shot_released = false
	_release_timer = 0.0


func physics_process(delta: float) -> State:
	player.update_turbo(delta)
	player.apply_gravity(delta)
	player.apply_movement(delta, GameConfig.data.player_air_control)

	# Release ball at apex or after delay
	if not _shot_released:
		_release_timer += delta
		if _release_timer >= GameConfig.data.shot_release_delay or player.height_velocity <= 0.0:
			_release_shot()

	# Land
	if player.is_on_ground():
		var dir := player.get_input_direction()
		if dir != Vector2.ZERO:
			return state_machine.get_state("Running")
		return state_machine.get_state("Idle")

	return null


func _release_shot() -> void:
	_shot_released = true
	if player.has_ball():
		player.try_shoot()

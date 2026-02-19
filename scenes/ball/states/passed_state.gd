class_name PassedBallState
extends BallState
## Ball in flight toward a pass target. Straight line with height arc.

var _start_pos: Vector2
var _total_distance: float = 0.0


func enter() -> void:
	_start_pos = ball.global_position
	_total_distance = 0.0
	if ball.pass_target:
		_total_distance = _start_pos.distance_to(ball.pass_target.global_position)
	ball.height = GameConfig.data.pass_initial_height


func physics_process(delta: float) -> State:
	if ball.pass_target == null or _total_distance < 1.0:
		ball.ground_velocity = Vector2.ZERO
		return state_machine.get_state("Loose")

	var config := GameConfig.data

	# Move toward target's current position
	var target_pos := ball.pass_target.global_position
	var direction := (target_pos - ball.global_position).normalized()
	ball.global_position += direction * config.pass_speed * delta

	# Arc height: parabola peaking at midpoint
	var remaining := ball.global_position.distance_to(target_pos)
	var progress := clampf(1.0 - remaining / _total_distance, 0.0, 1.0)
	ball.height = config.pass_initial_height + config.pass_arc_height * config.pass_arc_curve_factor * progress * (1.0 - progress)

	# Check for interception by opponent
	var interceptor := ball.check_intercept()
	if interceptor:
		ball.pick_up(interceptor)
		return null

	# Arrived at target
	if remaining <= config.ball_pickup_radius:
		ball.pick_up(ball.pass_target)
		return null

	return null


func exit() -> void:
	ball.pass_target = null

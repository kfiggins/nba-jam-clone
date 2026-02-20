class_name LooseBallState
extends BallState
## Ball is loose on the court. Gravity, bounce, friction, and auto-pickup.


func physics_process(delta: float) -> State:
	ball.apply_ball_gravity(delta)

	# Ground-plane movement with friction
	ball.global_position += ball.ground_velocity * delta
	ball.ground_velocity = ball.ground_velocity.move_toward(Vector2.ZERO, GameConfig.data.ball_ground_friction * delta)

	# Out-of-bounds: clamp ball to court bounds
	var bounds := GameConfig.data.court_bounds
	if not bounds.has_point(ball.global_position):
		ball.ground_velocity = Vector2.ZERO
		ball.height_velocity = 0.0
		ball.global_position.x = clampf(ball.global_position.x, bounds.position.x, bounds.end.x)
		ball.global_position.y = clampf(ball.global_position.y, bounds.position.y, bounds.end.y)

	# No pickup during score pause — wait for possession reset
	if GameManager.score_pause_timer > 0.0:
		return null

	# Auto-pickup: nearest player within radius and ball near ground
	var config := GameConfig.data
	for node in ball.get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p == null:
			continue
		var dist := ball.global_position.distance_to(p.global_position)
		if dist <= config.ball_pickup_radius and ball.height <= config.ball_pickup_height_threshold:
			ball.pick_up(p)
			return null

	return null

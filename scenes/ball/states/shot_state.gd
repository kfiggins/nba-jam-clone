class_name ShotBallState
extends BallState
## Ball in flight toward the basket after a shot.
## Follows a parabolic arc, then resolves make/miss on arrival.

var _start_pos: Vector2
var _target_pos: Vector2
var _total_distance: float = 0.0
var _start_height: float = 0.0
var _rim_height: float = 120.0
var _block_timer: float = 0.0


func enter() -> void:
	_block_timer = 0.0
	_start_pos = ball.global_position
	_start_height = ball.height
	ball.height_velocity = 0.0
	ball.ground_velocity = Vector2.ZERO

	var basket := _find_basket()
	if basket:
		_target_pos = basket.global_position
		_rim_height = basket.rim_height
	else:
		# Fallback: aim toward right side of court
		_target_pos = Vector2(1130, 360)

	_total_distance = _start_pos.distance_to(_target_pos)


func physics_process(delta: float) -> State:
	if _total_distance < 1.0:
		return state_machine.get_state("Loose")

	var config := GameConfig.data
	var direction := (_target_pos - ball.global_position).normalized()
	ball.global_position += direction * config.shot_speed * delta

	# Arc height: blend from start height to ground, plus parabolic arc overlay
	var remaining := ball.global_position.distance_to(_target_pos)
	var progress := clampf(1.0 - remaining / _total_distance, 0.0, 1.0)
	var peak := config.shot_arc_height
	var base_height := lerpf(_start_height, 0.0, progress)
	ball.height = base_height + peak * config.shot_arc_curve_factor * progress * (1.0 - progress)

	# Block check during block window
	_block_timer += delta
	if _block_timer <= config.block_window and ball.shot_shooter:
		var blocker := ball.check_shot_block(ball.shot_shooter)
		if blocker:
			if config.enable_goaltending and progress >= config.goaltending_progress:
				_award_goaltending()
				return null
			ball.shot_shooter.apply_block_stun()
			ball.deflect(blocker, ball.shot_shooter)
			return null

	# Reached the basket
	if remaining <= config.shot_resolution_distance:
		_resolve_shot()
		return null

	return null


func exit() -> void:
	ball.shot_shooter = null


func _resolve_shot() -> void:
	var config := GameConfig.data
	var shooter := ball.shot_shooter
	var distance := _start_pos.distance_to(_target_pos)
	var success_chance := _calculate_success_chance(distance)
	var roll := randf()

	if roll < success_chance:
		# Made shot
		var points := _get_points(config, distance)
		ball.shot_made.emit(shooter, points)
		if shooter:
			GameManager.add_score(shooter.team, points)
		# Ball drops through basket
		ball.ground_velocity = config.shot_made_drop_velocity
		ball.height = config.shot_made_height
		ball.height_velocity = config.shot_made_height_velocity
	else:
		# Missed shot — ball bounces off rim
		ball.shot_missed.emit(shooter)
		var bounce_x := randf_range(-config.shot_miss_bounce_max, config.shot_miss_bounce_max)
		var bounce_y := randf_range(-config.shot_miss_bounce_max, -config.shot_miss_bounce_min)
		ball.ground_velocity = Vector2(bounce_x, bounce_y)
		ball.height = _rim_height * config.shot_miss_rim_height_factor
		ball.height_velocity = randf_range(config.shot_miss_bounce_min, config.shot_miss_bounce_max)

	state_machine.change_state(state_machine.get_state("Loose"))


func _calculate_success_chance(distance: float) -> float:
	var config := GameConfig.data
	var chance: float
	if distance <= config.shot_close_range:
		chance = config.shot_success_close
	else:
		# Linear falloff from close to base over 3x the close range
		var far_range := config.shot_close_range * 3.0
		var t := clampf((distance - config.shot_close_range) / (far_range - config.shot_close_range), 0.0, 1.0)
		chance = lerpf(config.shot_success_close, config.shot_success_base, t)
	# On Fire bonus
	if ball.shot_shooter and ball.shot_shooter.is_on_fire:
		chance += config.fire_shot_bonus
	# Archetype modifier
	if ball.shot_shooter:
		chance *= ball.shot_shooter.get_stat_modifier("shot_accuracy")
	return clampf(chance, 0.0, 1.0)


func _get_points(config: GameConfigData, distance: float) -> int:
	if config.enable_three_point_zone and distance > config.three_point_distance:
		return config.points_per_three
	return config.points_per_shot


func _award_goaltending() -> void:
	var config := GameConfig.data
	var shooter := ball.shot_shooter
	var distance := _start_pos.distance_to(_target_pos)
	var points := _get_points(config, distance)
	ball.shot_made.emit(shooter, points)
	if shooter:
		GameManager.add_score(shooter.team, points)
	ball.ground_velocity = config.shot_made_drop_velocity
	ball.height = config.shot_made_height
	ball.height_velocity = config.shot_made_height_velocity
	state_machine.change_state(state_machine.get_state("Loose"))


func _find_basket() -> Node:
	for node in ball.get_tree().get_nodes_in_group("basket"):
		return node
	return null

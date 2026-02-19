class_name AIController
extends Node
## AI brain that drives a non-human Player.
## Evaluates game state on a timer and sets movement + action flags.

var player: Player
var _think_timer: float = 0.0
var _steal_cooldown: float = 0.0

const SWEET_SPOTS: Array[Vector2] = [
	Vector2(-120, -60),
	Vector2(-120, 60),
	Vector2(-180, 0),
]


func _ready() -> void:
	player = get_parent() as Player
	if player == null:
		return
	_think_timer = randf_range(0.0, GameConfig.data.ai_reaction_speed)


func _physics_process(delta: float) -> void:
	if player == null or player.is_human:
		return
	if GameManager.state != GameManager.MatchState.PLAYING:
		player.input_direction = Vector2.ZERO
		return

	_think_timer -= delta
	if _steal_cooldown > 0.0:
		_steal_cooldown -= delta

	if _think_timer <= 0.0:
		var variance := GameConfig.data.ai_reaction_speed_variance
		_think_timer = GameConfig.data.ai_reaction_speed + randf_range(-variance, variance)
		_evaluate()


func _evaluate() -> void:
	_clear_flags()

	if player == null or player.is_human:
		return

	var ball := _get_ball()
	if ball == null:
		return

	if player.has_ball():
		_evaluate_offense_with_ball(ball)
	elif ball.current_owner != null and ball.current_owner.team == player.team:
		_evaluate_offense_without_ball(ball)
	elif ball.current_owner != null and ball.current_owner.team != player.team:
		_evaluate_defense(ball)
	else:
		_evaluate_loose_ball(ball)


func _evaluate_offense_with_ball(ball: Ball) -> void:
	var config := GameConfig.data
	var basket_pos := _get_basket_position()
	var dist_to_basket := player.global_position.distance_to(basket_pos)

	# 1. In dunk range -> dunk
	if player.is_in_dunk_range():
		player.ai_shoot_requested = true
		player.input_direction = (basket_pos - player.global_position).normalized()
		return

	# 2. Close enough to shoot and open
	if dist_to_basket < config.ai_shoot_range:
		var nearest_def := _nearest_defender_distance()
		if nearest_def > config.ai_open_threshold or randf() < config.ai_aggression:
			player.ai_shoot_requested = true
			player.input_direction = Vector2.ZERO
			return

	# 3. Teammate closer to basket -> pass
	var teammate := _get_teammate()
	if teammate:
		var tm_dist := teammate.global_position.distance_to(basket_pos)
		if tm_dist < dist_to_basket - config.ai_pass_advantage:
			player.ai_pass_requested = true
			return

	# 4. Move toward scoring position
	var target := _pick_scoring_position(basket_pos)
	player.input_direction = (target - player.global_position).normalized()
	player.ai_sprint_requested = dist_to_basket > config.ai_shoot_range


func _evaluate_offense_without_ball(ball: Ball) -> void:
	var basket_pos := _get_basket_position()
	var target := _pick_scoring_position(basket_pos)
	var dist_to_target := player.global_position.distance_to(target)

	if dist_to_target < GameConfig.data.ai_movement_stop_distance:
		player.input_direction = Vector2.ZERO
	else:
		player.input_direction = (target - player.global_position).normalized()


func _evaluate_defense(ball: Ball) -> void:
	var config := GameConfig.data
	var handler := ball.current_owner
	if handler == null:
		return

	# Defend the basket the opponent is attacking (our defensive basket)
	var basket_pos := _get_defensive_basket_position()
	var dist_to_handler := player.global_position.distance_to(handler.global_position)

	# 1. Opponent shooting/dunking -> jump to block
	if handler.state_machine and handler.state_machine.current_state:
		var state_name := handler.state_machine.current_state.name
		if state_name == "Shooting" or state_name == "Dunking":
			if dist_to_handler <= config.ai_block_react_range and player.is_on_ground():
				player.ai_shoot_requested = true
				player.input_direction = (handler.global_position - player.global_position).normalized()
				return

	# 2. Close to handler -> try steal
	if dist_to_handler <= GameConfig.data.steal_range + 10.0:
		if _steal_cooldown <= 0.0 and randf() < config.ai_aggression:
			player.ai_steal_requested = true
			_steal_cooldown = config.ai_steal_cooldown
			return

	# 3. Beaten (handler closer to basket) -> recover
	var handler_to_basket := basket_pos.distance_to(handler.global_position)
	var us_to_basket := basket_pos.distance_to(player.global_position)
	if us_to_basket > handler_to_basket + config.ai_recovery_threshold:
		player.input_direction = (basket_pos - player.global_position).normalized()
		player.ai_sprint_requested = true
		return

	# 4. Guard: move between handler and basket
	var guard_pos := handler.global_position + (basket_pos - handler.global_position).normalized() * config.ai_guard_distance
	player.input_direction = (guard_pos - player.global_position).normalized()
	player.ai_sprint_requested = dist_to_handler > 100.0


func _evaluate_loose_ball(ball: Ball) -> void:
	player.input_direction = (ball.global_position - player.global_position).normalized()
	player.ai_sprint_requested = true


func _clear_flags() -> void:
	if player == null:
		return
	player.ai_shoot_requested = false
	player.ai_pass_requested = false
	player.ai_steal_requested = false
	player.ai_sprint_requested = false


# -- Helpers --

func _get_ball() -> Ball:
	for node in player.get_tree().get_nodes_in_group("ball"):
		return node as Ball
	return null


func _get_basket_position() -> Vector2:
	for node in player.get_tree().get_nodes_in_group("basket"):
		var basket := node as Basket
		if basket and basket.team_target == player.team:
			return basket.global_position
	# Fallback
	for node in player.get_tree().get_nodes_in_group("basket"):
		return node.global_position
	return Vector2(1130, 360)


func _get_defensive_basket_position() -> Vector2:
	# The basket the opponent attacks (team_target != our team)
	for node in player.get_tree().get_nodes_in_group("basket"):
		var basket := node as Basket
		if basket and basket.team_target != player.team:
			return basket.global_position
	return _get_basket_position()


func _get_teammate() -> Player:
	for node in player.get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p != null and p != player and p.team == player.team:
			return p
	return null


func _nearest_defender_distance() -> float:
	var min_dist := INF
	for node in player.get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p != null and p.team != player.team:
			var d := player.global_position.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d
	return min_dist


func _pick_scoring_position(basket_pos: Vector2) -> Vector2:
	# Mirror sweet spots for left-side basket (team 2)
	var x_flip := -1.0 if basket_pos.x < 640.0 else 1.0
	var best_pos := basket_pos + Vector2(SWEET_SPOTS[0].x * x_flip, SWEET_SPOTS[0].y)
	var best_score := -INF
	for offset in SWEET_SPOTS:
		var pos := basket_pos + Vector2(offset.x * x_flip, offset.y)
		var dist_to_us := player.global_position.distance_to(pos)
		var min_def := _min_defender_dist_to(pos)
		var score := min_def - dist_to_us * 0.5
		if score > best_score:
			best_score = score
			best_pos = pos
	return best_pos


func _min_defender_dist_to(pos: Vector2) -> float:
	var min_dist := INF
	for node in player.get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p != null and p.team != player.team:
			var d := pos.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d
	return min_dist

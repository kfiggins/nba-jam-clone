extends GutTest

var _ball: Ball
var _player1: Player
var _player2: Player
var _basket: Node2D
var _config: Node
var _manager: Node


func before_each() -> void:
	_config = load("res://scripts/autoload/game_config.gd").new()
	_config.name = "GameConfig"
	add_child(_config)
	_manager = load("res://scripts/autoload/game_manager.gd").new()
	_manager.name = "GameManager"
	add_child(_manager)
	GameManager.scores = [0, 0]
	GameManager.state = GameManager.MatchState.PLAYING
	GameManager.time_remaining = 120.0


func after_each() -> void:
	for p in [_player1, _player2]:
		if p:
			p.process_mode = Node.PROCESS_MODE_DISABLED
			p.remove_from_group("players")
			p.queue_free()
	_player1 = null
	_player2 = null
	if _ball:
		_ball.process_mode = Node.PROCESS_MODE_DISABLED
		_ball.remove_from_group("ball")
		_ball.queue_free()
		_ball = null
	if _basket:
		_basket.remove_from_group("basket")
		_basket.queue_free()
		_basket = null
	_manager.queue_free()
	_config.queue_free()


# -- Helpers --

func _make_player(team_id: int, pos: Vector2, human: bool = false) -> Player:
	var p := Player.new()
	p.is_human = human
	p.team = team_id
	p.position = pos
	var sprite := Node2D.new()
	sprite.name = "Sprite"
	p.add_child(sprite)
	var shadow := Node2D.new()
	shadow.name = "Shadow"
	p.add_child(shadow)
	var sm := StateMachine.new()
	sm.name = "StateMachine"
	p.add_child(sm)
	add_child(p)
	p.add_to_group("players")
	return p


func _add_ball(pos: Vector2 = Vector2(900, 900)) -> void:
	_ball = Ball.new()
	_ball.position = pos
	var sprite := Node2D.new()
	sprite.name = "Sprite"
	_ball.add_child(sprite)
	var shadow := Node2D.new()
	shadow.name = "Shadow"
	_ball.add_child(shadow)
	var sm := StateMachine.new()
	sm.name = "StateMachine"
	var held := HeldBallState.new()
	held.name = "Held"
	sm.add_child(held)
	var loose := LooseBallState.new()
	loose.name = "Loose"
	sm.add_child(loose)
	var passed := PassedBallState.new()
	passed.name = "Passed"
	sm.add_child(passed)
	var shot := ShotBallState.new()
	shot.name = "Shot"
	sm.add_child(shot)
	_ball.add_child(sm)
	for state_node in sm.get_children():
		state_node.owner = _ball
	_ball.add_to_group("ball")
	add_child(_ball)


func _add_basket(pos: Vector2 = Vector2(1130, 360)) -> void:
	_basket = Basket.new()
	_basket.position = pos
	_basket.add_to_group("basket")
	add_child(_basket)


# =============================================================================
# Streak counting tests
# =============================================================================

func test_add_streak_increments_count() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	_player1.add_streak()
	assert_eq(_player1.streak_count, 1)
	_player1.add_streak()
	assert_eq(_player1.streak_count, 2)

func test_fire_triggers_at_threshold() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	for i in range(GameConfig.data.fire_streak_threshold):
		_player1.add_streak()
	assert_true(_player1.is_on_fire, "Should be on fire after 3 consecutive makes")

func test_no_fire_below_threshold() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	_player1.add_streak()
	_player1.add_streak()
	assert_false(_player1.is_on_fire, "Should not be on fire with only 2 makes")

func test_streak_keeps_incrementing_past_threshold() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	for i in range(5):
		_player1.add_streak()
	assert_eq(_player1.streak_count, 5)
	assert_true(_player1.is_on_fire)


# =============================================================================
# Streak reset tests
# =============================================================================

func test_reset_streak_zeroes_count() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	_player1.add_streak()
	_player1.add_streak()
	_player1.reset_streak()
	assert_eq(_player1.streak_count, 0)

func test_reset_clears_on_fire() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	for i in range(3):
		_player1.add_streak()
	assert_true(_player1.is_on_fire)
	_player1.reset_streak()
	assert_false(_player1.is_on_fire, "Reset should clear on fire state")

func test_reset_when_not_on_fire_no_signal() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	watch_signals(_player1)
	_player1.add_streak()
	_player1.reset_streak()
	assert_signal_not_emitted(_player1, "fire_ended")


# =============================================================================
# Signal tests
# =============================================================================

func test_caught_fire_signal_at_threshold() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	watch_signals(_player1)
	for i in range(3):
		_player1.add_streak()
	assert_signal_emitted(_player1, "caught_fire")

func test_fire_ended_signal_on_reset() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	for i in range(3):
		_player1.add_streak()
	watch_signals(_player1)
	_player1.reset_streak()
	assert_signal_emitted(_player1, "fire_ended")

func test_no_double_caught_fire() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	watch_signals(_player1)
	for i in range(5):
		_player1.add_streak()
	assert_signal_emit_count(_player1, "caught_fire", 1,
		"Should only emit caught_fire once")


# =============================================================================
# Fire bonus tests
# =============================================================================

func test_fire_bonus_increases_success_chance() -> void:
	_add_ball(Vector2(400, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 360))
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	var shot_state: ShotBallState = _ball.state_machine.current_state as ShotBallState
	# Normal chance at distance 730
	var normal_chance := shot_state._calculate_success_chance(500.0)
	# Set on fire and check again
	_player1.is_on_fire = true
	_ball.shot_shooter = _player1
	var fire_chance := shot_state._calculate_success_chance(500.0)
	assert_gt(fire_chance, normal_chance, "Fire should boost success chance")

func test_fire_close_shot_guaranteed() -> void:
	_add_ball(Vector2(1050, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(1050, 360))
	_player1.is_on_fire = true
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	var shot_state: ShotBallState = _ball.state_machine.current_state as ShotBallState
	# Close range (80) = 0.85 + 0.3 fire bonus = 1.0 (clamped)
	var chance := shot_state._calculate_success_chance(80.0)
	assert_eq(chance, 1.0, "Close shot while on fire should be guaranteed")

func test_no_bonus_when_not_on_fire() -> void:
	_add_ball(Vector2(400, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 360))
	_player1.is_on_fire = false
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	var shot_state: ShotBallState = _ball.state_machine.current_state as ShotBallState
	var chance := shot_state._calculate_success_chance(500.0)
	# Should be base calculation without fire bonus
	var config := GameConfig.data
	var far_range := config.shot_close_range * 3.0
	var t := clampf((500.0 - config.shot_close_range) / (far_range - config.shot_close_range), 0.0, 1.0)
	var expected := lerpf(config.shot_success_close, config.shot_success_base, t)
	assert_almost_eq(chance, expected, 0.01, "No bonus when not on fire")

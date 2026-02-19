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
	GameManager.last_scoring_team = 0
	GameManager.score_pause_timer = 0.0
	GameManager.shot_clock_remaining = 0.0
	GameManager.shot_clock_team = 0


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


func _add_ball(pos: Vector2 = Vector2(640, 360)) -> void:
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
# Config tests
# =============================================================================

func test_config_three_point_distance() -> void:
	assert_eq(GameConfig.data.three_point_distance, 400.0)

func test_config_score_pause_duration() -> void:
	assert_eq(GameConfig.data.score_pause_duration, 1.0)

func test_config_inbound_position() -> void:
	assert_eq(GameConfig.data.inbound_position, Vector2(300, 360))

func test_config_court_bounds() -> void:
	assert_eq(GameConfig.data.court_bounds, Rect2(80, 80, 1120, 560))

func test_config_shot_clock_disabled_by_default() -> void:
	assert_false(GameConfig.data.enable_shot_clock)

func test_config_shot_clock_duration() -> void:
	assert_eq(GameConfig.data.shot_clock_duration, 24.0)


# =============================================================================
# 3-point zone tests
# =============================================================================

func test_three_point_awards_3_when_enabled() -> void:
	GameConfig.data.enable_three_point_zone = true
	_add_ball(Vector2(400, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 360))
	_ball.pick_up(_player1)
	seed(1)  # Ensure shot succeeds (close range = 85%)
	_ball.shoot(_player1)
	# Shot state calculates distance = 730 > three_point_distance (400)
	# Process the shot to completion
	for i in range(300):
		_ball.state_machine._physics_process(0.016)
	assert_eq(GameManager.get_score(1), 3, "Should award 3 points for long shot")
	GameConfig.data.enable_three_point_zone = false

func test_three_point_awards_2_when_disabled() -> void:
	GameConfig.data.enable_three_point_zone = false
	_add_ball(Vector2(400, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 360))
	_ball.pick_up(_player1)
	seed(1)
	_ball.shoot(_player1)
	for i in range(300):
		_ball.state_machine._physics_process(0.016)
	assert_eq(GameManager.get_score(1), 2, "Should award 2 points when 3pt disabled")

func test_close_shot_always_2_points() -> void:
	GameConfig.data.enable_three_point_zone = true
	_add_ball(Vector2(1050, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(1050, 360))
	_ball.pick_up(_player1)
	seed(1)
	_ball.shoot(_player1)
	for i in range(300):
		_ball.state_machine._physics_process(0.016)
	# Distance = 80 < three_point_distance (400)
	assert_eq(GameManager.get_score(1), 2, "Close shot should always be 2 points")
	GameConfig.data.enable_three_point_zone = false


# =============================================================================
# Possession change tests
# =============================================================================

func test_add_score_sets_last_scoring_team() -> void:
	GameManager.add_score(1, 2)
	assert_eq(GameManager.last_scoring_team, 1)

func test_add_score_starts_pause_timer() -> void:
	GameManager.add_score(2, 2)
	assert_gt(GameManager.score_pause_timer, 0.0, "Pause timer should start after scoring")

func test_possession_reset_emitted_after_pause() -> void:
	watch_signals(GameManager)
	GameManager.add_score(1, 2)
	# Tick past the pause duration
	for i in range(100):
		GameManager._process_playing(0.016)
	assert_signal_emitted(GameManager, "possession_reset")

func test_possession_reset_gives_to_other_team() -> void:
	watch_signals(GameManager)
	GameManager.add_score(1, 2)
	for i in range(100):
		GameManager._process_playing(0.016)
	assert_signal_emitted_with_parameters(GameManager, "possession_reset", [2])

func test_possession_reset_team1_scores_team2_receives() -> void:
	watch_signals(GameManager)
	GameManager.add_score(2, 2)
	for i in range(100):
		GameManager._process_playing(0.016)
	assert_signal_emitted_with_parameters(GameManager, "possession_reset", [1])


# =============================================================================
# Ball reset tests
# =============================================================================

func test_ball_reset_to_teleports() -> void:
	_add_ball(Vector2(900, 500))
	_ball.height = 50.0
	_ball.height_velocity = 100.0
	_ball.ground_velocity = Vector2(200, 100)
	_ball.reset_to(Vector2(300, 360))
	assert_eq(_ball.global_position, Vector2(300, 360))
	assert_eq(_ball.height, 0.0)
	assert_eq(_ball.height_velocity, 0.0)
	assert_eq(_ball.ground_velocity, Vector2.ZERO)

func test_ball_reset_to_with_receiver() -> void:
	_add_ball(Vector2(900, 500))
	_player1 = _make_player(1, Vector2(300, 360))
	_ball.reset_to(Vector2(300, 360), _player1)
	assert_eq(_ball.current_owner, _player1)
	assert_eq(_player1.held_ball, _ball)

func test_ball_reset_clears_previous_owner() -> void:
	_add_ball(Vector2(400, 300))
	_player1 = _make_player(1, Vector2(400, 300))
	_player2 = _make_player(2, Vector2(300, 360))
	_ball.pick_up(_player1)
	assert_eq(_player1.held_ball, _ball)
	_ball.reset_to(Vector2(300, 360), _player2)
	assert_null(_player1.held_ball, "Previous owner should lose ball")
	assert_eq(_ball.current_owner, _player2)


# =============================================================================
# Out-of-bounds tests
# =============================================================================

func test_ball_clamped_to_court_bounds() -> void:
	_add_ball(Vector2(50, 50))  # Outside bounds (80, 80, 1120, 560)
	_ball.ground_velocity = Vector2(-200, -200)
	_ball.height = 0.0
	# Process loose state
	var loose := _ball.state_machine.get_state("Loose")
	loose.physics_process(0.016)
	assert_gte(_ball.global_position.x, 80.0, "Ball X should be clamped to left bound")
	assert_gte(_ball.global_position.y, 80.0, "Ball Y should be clamped to top bound")

func test_ball_velocity_zeroed_on_oob() -> void:
	_add_ball(Vector2(50, 360))
	_ball.ground_velocity = Vector2(-200, 0)
	_ball.height = 0.0
	var loose := _ball.state_machine.get_state("Loose")
	loose.physics_process(0.016)
	assert_eq(_ball.ground_velocity, Vector2.ZERO, "Velocity should zero on OOB")

func test_ball_stays_in_bounds_right_edge() -> void:
	_add_ball(Vector2(1250, 360))
	_ball.ground_velocity = Vector2(200, 0)
	_ball.height = 0.0
	var loose := _ball.state_machine.get_state("Loose")
	loose.physics_process(0.016)
	# Bounds end.x = 80 + 1120 = 1200
	assert_lte(_ball.global_position.x, 1200.0, "Ball should be clamped to right bound")

func test_ball_in_bounds_not_clamped() -> void:
	_add_ball(Vector2(640, 360))
	_ball.ground_velocity = Vector2(100, 0)
	_ball.height = 0.0
	var loose := _ball.state_machine.get_state("Loose")
	loose.physics_process(0.016)
	# Ball at center should not be affected by bounds
	assert_gt(_ball.global_position.x, 640.0, "Ball should move freely within bounds")
	assert_gt(_ball.ground_velocity.length(), 0.0, "Velocity should not be zeroed in bounds")


# =============================================================================
# Shot clock tests
# =============================================================================

func test_shot_clock_ticks_when_enabled() -> void:
	GameConfig.data.enable_shot_clock = true
	GameManager.on_possession_changed(1)
	assert_eq(GameManager.shot_clock_remaining, 24.0)
	GameManager._process_playing(1.0)
	assert_almost_eq(GameManager.shot_clock_remaining, 23.0, 0.1)
	GameConfig.data.enable_shot_clock = false

func test_shot_clock_resets_on_possession_change() -> void:
	GameConfig.data.enable_shot_clock = true
	GameManager.on_possession_changed(1)
	GameManager._process_playing(10.0)
	GameManager.on_possession_changed(2)
	assert_eq(GameManager.shot_clock_remaining, 24.0, "Clock should reset on new possession")
	assert_eq(GameManager.shot_clock_team, 2)
	GameConfig.data.enable_shot_clock = false

func test_shot_clock_expired_triggers_possession_reset() -> void:
	GameConfig.data.enable_shot_clock = true
	watch_signals(GameManager)
	GameManager.on_possession_changed(1)
	# Tick past 24 seconds
	for i in range(30):
		GameManager._process_playing(1.0)
	assert_signal_emitted(GameManager, "shot_clock_expired")
	assert_signal_emitted(GameManager, "possession_reset")
	GameConfig.data.enable_shot_clock = false

func test_shot_clock_no_tick_when_disabled() -> void:
	GameConfig.data.enable_shot_clock = false
	GameManager.on_possession_changed(1)
	assert_eq(GameManager.shot_clock_remaining, 0.0, "Clock should not start when disabled")


# =============================================================================
# No fouls test
# =============================================================================

func test_no_foul_system_exists() -> void:
	# Defensive actions (steal, block, bump) work without foul penalties
	# This test verifies no foul-related config or state exists
	assert_false("foul" in str(GameConfig.data.get_property_list()),
		"No foul properties should exist in config")

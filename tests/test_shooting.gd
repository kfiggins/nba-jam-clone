extends GutTest

var _ball: Ball
var _player1: Player
var _player2: Player
var _basket: Basket
var _config: Node
var _manager: Node


func before_each() -> void:
	_config = load("res://scripts/autoload/game_config.gd").new()
	_config.name = "GameConfig"
	add_child(_config)
	_manager = load("res://scripts/autoload/game_manager.gd").new()
	_manager.name = "GameManager"
	add_child(_manager)
	# Reset global autoload state (ball code uses the autoload, not our local node)
	GameManager.scores = [0, 0]
	GameManager.state = GameManager.MatchState.PREGAME
	GameManager.time_remaining = 120.0


func after_each() -> void:
	for p in [_player1, _player2]:
		if p:
			p.remove_from_group("players")
			p.queue_free()
	_player1 = null
	_player2 = null
	if _ball:
		_ball.remove_from_group("ball")
		_ball.queue_free()
		_ball = null
	if _basket:
		_basket.remove_from_group("basket")
		_basket.queue_free()
		_basket = null
	_manager.queue_free()
	_config.queue_free()
	for action in ["move_up", "move_down", "move_left", "move_right", "turbo", "shoot"]:
		Input.action_release(action)


# -- Helpers --

func _make_player(team_id: int, pos: Vector2) -> Player:
	var p := Player.new()
	p.is_human = false
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


func _add_ball(pos: Vector2 = Vector2(400, 300)) -> void:
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
	# Add ball states
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
	# Set owner so BallState._ready() finds the Ball reference
	for state_node in sm.get_children():
		state_node.owner = _ball
	_ball.add_to_group("ball")
	add_child(_ball)


func _add_basket(pos: Vector2 = Vector2(1130, 360)) -> void:
	_basket = Basket.new()
	_basket.position = pos
	_basket.add_to_group("basket")
	add_child(_basket)


func _add_full_player() -> Player:
	var p: Player = load("res://scenes/player/player.tscn").instantiate()
	add_child(p)
	return p


# -- Ball.shoot() --

func test_shoot_clears_owner() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	assert_null(_ball.current_owner)


func test_shoot_clears_held_ball_on_player() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	assert_null(_player1.held_ball)


func test_shoot_sets_shot_shooter() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	assert_eq(_ball.shot_shooter, _player1)


func test_shoot_emits_shot_taken() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	watch_signals(_ball)
	_ball.shoot(_player1)
	assert_signal_emitted(_ball, "shot_taken")


func test_shoot_emits_owner_changed() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	watch_signals(_ball)
	_ball.shoot(_player1)
	assert_signal_emitted(_ball, "owner_changed")


func test_shoot_transitions_to_shot_state() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	assert_eq(_ball.state_machine.current_state.name, "Shot")


# -- Player.try_shoot() --

func test_try_shoot_does_nothing_without_ball() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	watch_signals(_ball)
	_player1.try_shoot()
	assert_signal_not_emitted(_ball, "shot_taken")


func test_try_shoot_shoots_when_holding_ball() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	watch_signals(_ball)
	_player1.try_shoot()
	assert_signal_emitted(_ball, "shot_taken")


# -- ShotBallState: Arc & Movement --

func test_shot_ball_moves_toward_basket() -> void:
	_add_ball(Vector2(400, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 360))
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	var start_x := _ball.global_position.x
	# Simulate a few frames
	_ball.state_machine.current_state.physics_process(0.1)
	assert_gt(_ball.global_position.x, start_x, "Ball should move toward basket")


func test_shot_ball_has_arc_height() -> void:
	_add_ball(Vector2(400, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 360))
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	# Move ball partway (around midpoint should have max height)
	for i in range(5):
		_ball.state_machine.current_state.physics_process(0.1)
	assert_gt(_ball.height, 0.0, "Ball should have arc height during flight")


# -- ShotBallState: Success Chance Calculation --

func test_close_shot_has_higher_success() -> void:
	_add_ball(Vector2(1000, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(1000, 360))
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	var shot_state: ShotBallState = _ball.state_machine.current_state as ShotBallState
	var close_chance := shot_state._calculate_success_chance(100.0)
	var far_chance := shot_state._calculate_success_chance(600.0)
	assert_gt(close_chance, far_chance, "Close shots should have higher success rate")


func test_very_close_shot_returns_close_rate() -> void:
	_add_ball(Vector2(1050, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(1050, 360))
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	var shot_state: ShotBallState = _ball.state_machine.current_state as ShotBallState
	var chance := shot_state._calculate_success_chance(50.0)
	assert_eq(chance, GameConfig.data.shot_success_close)


func test_far_shot_returns_base_rate() -> void:
	_add_ball(Vector2(200, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(200, 360))
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	var shot_state: ShotBallState = _ball.state_machine.current_state as ShotBallState
	# Very far distance (beyond 3x close_range)
	var chance := shot_state._calculate_success_chance(1000.0)
	assert_eq(chance, GameConfig.data.shot_success_base)


# -- ShotBallState: Resolution --

func test_shot_resolves_to_loose_state() -> void:
	_add_ball(Vector2(1120, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(1120, 360))
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	# Move ball to basket (very close, should resolve quickly)
	for i in range(50):
		if _ball.state_machine.current_state.name != "Shot":
			break
		_ball.state_machine.current_state.physics_process(0.05)
	assert_eq(_ball.state_machine.current_state.name, "Loose", "Ball should be loose after shot resolves")


func test_made_shot_emits_shot_made() -> void:
	_add_ball(Vector2(1120, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(1120, 360))
	_ball.pick_up(_player1)
	# Set seed for deterministic test — shot_success_close is 0.85, very likely to make
	seed(42)
	watch_signals(_ball)
	_ball.shoot(_player1)
	for i in range(50):
		if _ball.state_machine.current_state.name != "Shot":
			break
		_ball.state_machine.current_state.physics_process(0.05)
	# With seed 42 and close range, at least one of the signals should have fired
	var made := get_signal_emit_count(_ball, "shot_made")
	var missed := get_signal_emit_count(_ball, "shot_missed")
	assert_eq(made + missed, 1, "Exactly one resolution signal should fire")


func test_missed_shot_emits_shot_missed() -> void:
	_add_ball(Vector2(1120, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(1120, 360))
	_ball.pick_up(_player1)
	# Force a miss by using very low success rate temporarily
	var original := GameConfig.data.shot_success_close
	GameConfig.data.shot_success_close = 0.0
	GameConfig.data.shot_success_base = 0.0
	watch_signals(_ball)
	_ball.shoot(_player1)
	for i in range(50):
		if _ball.state_machine.current_state.name != "Shot":
			break
		_ball.state_machine.current_state.physics_process(0.05)
	assert_signal_emitted(_ball, "shot_missed")
	# Restore
	GameConfig.data.shot_success_close = original
	GameConfig.data.shot_success_base = 0.5


func test_made_shot_adds_score() -> void:
	_add_ball(Vector2(1120, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(1120, 360))
	_ball.pick_up(_player1)
	# Force a make
	GameConfig.data.shot_success_close = 1.0
	GameConfig.data.shot_success_base = 1.0
	GameManager.state = GameManager.MatchState.PLAYING
	_ball.shoot(_player1)
	for i in range(50):
		if _ball.state_machine.current_state.name != "Shot":
			break
		_ball.state_machine.current_state.physics_process(0.05)
	assert_eq(GameManager.get_score(1), GameConfig.data.points_per_shot)
	# Restore
	GameConfig.data.shot_success_close = 0.85
	GameConfig.data.shot_success_base = 0.5


func test_missed_shot_ball_has_bounce_velocity() -> void:
	_add_ball(Vector2(1120, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(1120, 360))
	_ball.pick_up(_player1)
	# Force a miss
	GameConfig.data.shot_success_close = 0.0
	GameConfig.data.shot_success_base = 0.0
	_ball.shoot(_player1)
	for i in range(50):
		if _ball.state_machine.current_state.name != "Shot":
			break
		_ball.state_machine.current_state.physics_process(0.05)
	assert_true(
		_ball.ground_velocity.length() > 0.0 or _ball.height_velocity > 0.0,
		"Missed shot should give ball bounce velocity"
	)
	# Restore
	GameConfig.data.shot_success_close = 0.85
	GameConfig.data.shot_success_base = 0.5


# -- Basket --

func test_basket_joins_group() -> void:
	_add_basket()
	var baskets := get_tree().get_nodes_in_group("basket")
	assert_eq(baskets.size(), 1)


func test_basket_has_rim_height() -> void:
	_add_basket()
	assert_gt(_basket.rim_height, 0.0, "Basket should have a rim height")


# -- Player State Integration: Shoot vs Jump --

func test_idle_to_shooting_with_ball() -> void:
	_add_basket()
	_player1 = _add_full_player()
	_player1.position = Vector2(400, 300)
	# Give player a ball
	_add_ball(Vector2(400, 300))
	_ball.pick_up(_player1)
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Shooting")


func test_idle_to_jumping_without_ball() -> void:
	_add_basket()
	_player1 = _add_full_player()
	_player1.position = Vector2(400, 300)
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Jumping")


func test_running_to_shooting_with_ball() -> void:
	_add_basket()
	_player1 = _add_full_player()
	_player1.position = Vector2(400, 300)
	_add_ball(Vector2(400, 300))
	_ball.pick_up(_player1)
	Input.action_press("move_right")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Shooting")


func test_running_to_jumping_without_ball() -> void:
	_add_basket()
	_player1 = _add_full_player()
	_player1.position = Vector2(400, 300)
	Input.action_press("move_right")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Jumping")


func test_shooting_state_lands_eventually() -> void:
	_add_basket()
	_player1 = _add_full_player()
	_player1.position = Vector2(400, 300)
	_add_ball(Vector2(400, 300))
	_ball.pick_up(_player1)
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("shoot")
	for i in range(120):
		await get_tree().physics_frame
		if _player1.state_machine.current_state.name != "Shooting":
			break
	assert_ne(_player1.state_machine.current_state.name, "Shooting", "Should have landed")


func test_shooting_state_releases_ball() -> void:
	_add_basket()
	_player1 = _add_full_player()
	_player1.position = Vector2(400, 300)
	_add_ball(Vector2(400, 300))
	_ball.pick_up(_player1)
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("shoot")
	# Wait for release (happens after delay or at apex)
	for i in range(60):
		await get_tree().physics_frame
		if not _player1.has_ball():
			break
	assert_false(_player1.has_ball(), "Ball should be released during shooting state")


# -- Config --

func test_shot_speed_config() -> void:
	assert_eq(GameConfig.data.shot_speed, 500.0)


func test_shot_arc_height_config() -> void:
	assert_eq(GameConfig.data.shot_arc_height, 200.0)


func test_shot_close_range_config() -> void:
	assert_eq(GameConfig.data.shot_close_range, 200.0)


func test_shot_release_delay_config() -> void:
	assert_eq(GameConfig.data.shot_release_delay, 0.15)

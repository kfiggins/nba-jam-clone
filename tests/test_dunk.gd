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
	# Reset global autoload state (ball.dunk() uses the autoload, not our local node)
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


func _add_full_player(pos: Vector2 = Vector2(400, 300)) -> Player:
	var p: Player = load("res://scenes/player/player.tscn").instantiate()
	p.position = pos
	add_child(p)
	return p


# -- Ball.dunk() --

func test_dunk_clears_owner() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	GameManager.state = GameManager.MatchState.PLAYING
	_ball.dunk(_player1)
	assert_null(_ball.current_owner)


func test_dunk_clears_held_ball() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	GameManager.state = GameManager.MatchState.PLAYING
	_ball.dunk(_player1)
	assert_null(_player1.held_ball)


func test_dunk_emits_dunk_made() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	watch_signals(_ball)
	GameManager.state = GameManager.MatchState.PLAYING
	_ball.dunk(_player1)
	assert_signal_emitted(_ball, "dunk_made")


func test_dunk_emits_owner_changed() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	watch_signals(_ball)
	GameManager.state = GameManager.MatchState.PLAYING
	_ball.dunk(_player1)
	assert_signal_emitted(_ball, "owner_changed")


func test_dunk_adds_score() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	GameManager.state = GameManager.MatchState.PLAYING
	_ball.dunk(_player1)
	assert_eq(GameManager.get_score(1), GameConfig.data.points_per_shot)


func test_dunk_transitions_to_loose() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	GameManager.state = GameManager.MatchState.PLAYING
	_ball.dunk(_player1)
	assert_eq(_ball.state_machine.current_state.name, "Loose")


func test_dunk_guaranteed_score() -> void:
	# Dunk should always score, regardless of random rolls
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	GameManager.state = GameManager.MatchState.PLAYING
	for i in range(10):
		GameManager.scores = [0, 0]
		_ball.pick_up(_player1)
		_ball.dunk(_player1)
		assert_eq(GameManager.get_score(1), GameConfig.data.points_per_shot,
			"Dunk %d should always score" % i)


# -- Player.try_dunk() --

func test_try_dunk_does_nothing_without_ball() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	watch_signals(_ball)
	_player1.try_dunk()
	assert_signal_not_emitted(_ball, "dunk_made")


func test_try_dunk_dunks_when_holding_ball() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	watch_signals(_ball)
	GameManager.state = GameManager.MatchState.PLAYING
	_player1.try_dunk()
	assert_signal_emitted(_ball, "dunk_made")


# -- Player.is_in_dunk_range() --

func test_in_dunk_range_when_close() -> void:
	_add_ball()
	_add_basket(Vector2(500, 300))
	_player1 = _make_player(1, Vector2(450, 300))
	_ball.pick_up(_player1)
	assert_true(_player1.is_in_dunk_range())


func test_not_in_dunk_range_when_far() -> void:
	_add_ball()
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	assert_false(_player1.is_in_dunk_range())


func test_not_in_dunk_range_without_ball() -> void:
	_add_ball()
	_add_basket(Vector2(500, 300))
	_player1 = _make_player(1, Vector2(450, 300))
	assert_false(_player1.is_in_dunk_range())


# -- Player State Integration: Dunk vs Shoot --

func test_idle_to_dunking_near_basket() -> void:
	_add_basket(Vector2(500, 300))
	_player1 = _add_full_player(Vector2(450, 300))
	_add_ball(Vector2(450, 300))
	_ball.pick_up(_player1)
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Dunking")


func test_idle_to_shooting_far_from_basket() -> void:
	_add_basket(Vector2(1130, 360))
	_player1 = _add_full_player(Vector2(400, 300))
	_add_ball(Vector2(400, 300))
	_ball.pick_up(_player1)
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Shooting")


func test_running_to_dunking_near_basket() -> void:
	_add_basket(Vector2(500, 300))
	_player1 = _add_full_player(Vector2(450, 300))
	_add_ball(Vector2(450, 300))
	_ball.pick_up(_player1)
	Input.action_press("move_right")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Dunking")


func test_dunking_state_lands_eventually() -> void:
	_add_basket(Vector2(500, 300))
	_player1 = _add_full_player(Vector2(450, 300))
	_add_ball(Vector2(450, 300))
	_ball.pick_up(_player1)
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("shoot")
	for i in range(120):
		await get_tree().physics_frame
		if _player1.state_machine.current_state.name != "Dunking":
			break
	assert_ne(_player1.state_machine.current_state.name, "Dunking", "Should have landed")


func test_dunking_state_scores() -> void:
	_add_basket(Vector2(480, 300))
	_player1 = _add_full_player(Vector2(450, 300))
	_add_ball(Vector2(450, 300))
	_ball.pick_up(_player1)
	GameManager.state = GameManager.MatchState.PLAYING
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("shoot")
	# Wait for dunk to complete
	for i in range(120):
		await get_tree().physics_frame
		if not _player1.has_ball():
			break
	assert_gt(GameManager.get_score(1), 0, "Dunk should have scored")


# -- Config --

func test_dunk_speed_config() -> void:
	assert_eq(GameConfig.data.dunk_speed, 400.0)


func test_dunk_range_config() -> void:
	assert_eq(GameConfig.data.dunk_range, 100.0)

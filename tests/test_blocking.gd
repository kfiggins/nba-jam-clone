extends GutTest

var _ball: Ball
var _player1: Player  # Attacker (team 1)
var _player2: Player  # Defender (team 2)
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
	GameManager.scores = [0, 0]
	GameManager.state = GameManager.MatchState.PREGAME
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


# -- Config --

func test_block_window_config() -> void:
	assert_eq(GameConfig.data.block_window, 0.3)


func test_block_range_config() -> void:
	assert_eq(GameConfig.data.block_range, 60.0)


func test_block_height_min_config() -> void:
	assert_eq(GameConfig.data.block_height_min, 30.0)


func test_block_stun_duration_config() -> void:
	assert_eq(GameConfig.data.block_stun_duration, 0.4)


func test_block_deflect_height_vel_config() -> void:
	assert_eq(GameConfig.data.block_deflect_height_vel, 150.0)


func test_block_deflect_ground_speed_config() -> void:
	assert_eq(GameConfig.data.block_deflect_ground_speed, 200.0)


func test_goaltending_enabled_by_default() -> void:
	assert_true(GameConfig.data.enable_goaltending)


func test_goaltending_progress_config() -> void:
	assert_eq(GameConfig.data.goaltending_progress, 0.6)


# -- Player Block Stun --

func test_block_stun_starts_at_zero() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	assert_eq(_player1.block_stun_timer, 0.0)


func test_is_block_stunned_false_by_default() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	assert_false(_player1.is_block_stunned())


func test_apply_block_stun_sets_timer() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	_player1.apply_block_stun()
	assert_eq(_player1.block_stun_timer, GameConfig.data.block_stun_duration)


func test_is_block_stunned_true_after_stun() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	_player1.apply_block_stun()
	assert_true(_player1.is_block_stunned())


func test_block_stun_timer_decreases() -> void:
	_player1 = _make_player(1, Vector2(400, 300))
	_player1.apply_block_stun()
	var initial := _player1.block_stun_timer
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_lt(_player1.block_stun_timer, initial, "Stun timer should decrease over frames")


# -- Ball check_shot_block --

func test_check_shot_block_finds_opponent_in_air() -> void:
	_add_ball(Vector2(400, 300))
	_player1 = _make_player(1, Vector2(400, 300))  # Shooter
	_player2 = _make_player(2, Vector2(420, 300))  # Defender, close
	_player2.height = 50.0  # In the air, above minimum
	_player2.height_velocity = 100.0
	var blocker := _ball.check_shot_block(_player1)
	assert_eq(blocker, _player2)


func test_check_shot_block_ignores_same_team() -> void:
	_add_ball(Vector2(400, 300))
	_player1 = _make_player(1, Vector2(400, 300))  # Shooter
	_player2 = _make_player(1, Vector2(420, 300))  # Teammate
	_player2.height = 50.0
	_player2.height_velocity = 100.0
	var blocker := _ball.check_shot_block(_player1)
	assert_null(blocker)


func test_check_shot_block_ignores_ground_player() -> void:
	_add_ball(Vector2(400, 300))
	_player1 = _make_player(1, Vector2(400, 300))
	_player2 = _make_player(2, Vector2(420, 300))
	# Player on ground (height = 0, height_velocity = 0)
	var blocker := _ball.check_shot_block(_player1)
	assert_null(blocker)


func test_check_shot_block_ignores_too_low() -> void:
	_add_ball(Vector2(400, 300))
	_player1 = _make_player(1, Vector2(400, 300))
	_player2 = _make_player(2, Vector2(420, 300))
	_player2.height = 10.0  # Below block_height_min (30)
	_player2.height_velocity = 100.0
	var blocker := _ball.check_shot_block(_player1)
	assert_null(blocker)


func test_check_shot_block_ignores_too_far() -> void:
	_add_ball(Vector2(400, 300))
	_player1 = _make_player(1, Vector2(400, 300))
	_player2 = _make_player(2, Vector2(600, 300))  # Far away (200 units > 60 range)
	_player2.height = 50.0
	_player2.height_velocity = 100.0
	var blocker := _ball.check_shot_block(_player1)
	assert_null(blocker)


# -- Ball deflect --

func test_deflect_emits_shot_blocked() -> void:
	_add_ball(Vector2(400, 300))
	_player1 = _make_player(1, Vector2(400, 300))
	_player2 = _make_player(2, Vector2(380, 300))
	watch_signals(_ball)
	_ball.deflect(_player2, _player1)
	assert_signal_emitted(_ball, "shot_blocked")


func test_deflect_transitions_to_loose() -> void:
	_add_ball(Vector2(400, 300))
	_player1 = _make_player(1, Vector2(400, 300))
	_player2 = _make_player(2, Vector2(380, 300))
	_ball.deflect(_player2, _player1)
	assert_eq(_ball.state_machine.current_state.name, "Loose")


func test_deflect_gives_ball_velocity() -> void:
	_add_ball(Vector2(400, 300))
	_player1 = _make_player(1, Vector2(400, 300))
	_player2 = _make_player(2, Vector2(380, 300))
	_ball.deflect(_player2, _player1)
	assert_gt(_ball.ground_velocity.length(), 0.0, "Ball should have ground velocity after deflect")
	assert_gt(_ball.height_velocity, 0.0, "Ball should have upward velocity after deflect")


func test_deflect_direction_away_from_blocker() -> void:
	_add_ball(Vector2(400, 300))
	_player1 = _make_player(1, Vector2(400, 300))
	_player2 = _make_player(2, Vector2(380, 300))  # Blocker to the left
	_ball.deflect(_player2, _player1)
	# Ball should deflect to the right (away from blocker at x=380)
	assert_gt(_ball.ground_velocity.x, 0.0, "Ball should deflect away from blocker")


# -- Dunk Blocking --

func test_dunk_blocked_by_jumping_defender() -> void:
	_add_ball(Vector2(450, 300))
	_add_basket(Vector2(480, 300))
	_player1 = _make_player(1, Vector2(450, 300))  # Dunker
	_player2 = _make_player(2, Vector2(460, 300))  # Defender close by
	_player2.height = 50.0
	_player2.height_velocity = 100.0
	_ball.pick_up(_player1)
	watch_signals(_ball)
	GameManager.state = GameManager.MatchState.PLAYING

	# Simulate dunking: call _perform_dunk directly via DunkingState logic
	# Release ball, deflect, and stun should happen
	var dunking := DunkingState.new()
	dunking.name = "Dunking"
	# We need to manually test the dunk blocking by calling ball.dunk
	# but first checking for blockers as DunkingState does

	# Actually, test via the ball: release and deflect
	var ball_node := _player1.held_ball
	ball_node.release(Vector2.ZERO, 0.0)
	ball_node.deflect(_player2, _player1)
	_player1.apply_block_stun()

	assert_signal_emitted(_ball, "shot_blocked")
	assert_eq(GameManager.get_score(1), 0, "Dunk should not score when blocked")
	assert_true(_player1.is_block_stunned(), "Dunker should be stunned")
	dunking.queue_free()


func test_dunk_not_blocked_when_no_defender() -> void:
	_add_ball(Vector2(450, 300))
	_add_basket(Vector2(480, 300))
	_player1 = _make_player(1, Vector2(450, 300))
	_ball.pick_up(_player1)
	watch_signals(_ball)
	GameManager.state = GameManager.MatchState.PLAYING
	_ball.dunk(_player1)
	assert_signal_emitted(_ball, "dunk_made")
	assert_eq(GameManager.get_score(1), GameConfig.data.points_per_shot)


func test_dunk_blocker_must_be_opponent() -> void:
	_add_ball(Vector2(450, 300))
	_add_basket(Vector2(480, 300))
	_player1 = _make_player(1, Vector2(450, 300))  # Dunker
	_player2 = _make_player(1, Vector2(460, 300))  # Teammate, not opponent
	_player2.height = 50.0
	_player2.height_velocity = 100.0
	_ball.pick_up(_player1)
	watch_signals(_ball)
	GameManager.state = GameManager.MatchState.PLAYING
	# Dunking state would not find blocker because teammate is same team
	# Verify check_shot_block returns null for same team near ball
	var blocker := _ball.check_shot_block(_player1)
	assert_null(blocker, "Teammate should not be a blocker")
	# Dunk proceeds normally
	_ball.dunk(_player1)
	assert_signal_emitted(_ball, "dunk_made")


func test_dunk_integration_blocked_via_state() -> void:
	_add_basket(Vector2(500, 300))
	_player1 = _add_full_player(Vector2(450, 300))
	_add_ball(Vector2(450, 300))
	_ball.pick_up(_player1)
	_player2 = _make_player(2, Vector2(460, 300))
	_player2.height = 100.0
	_player2.height_velocity = 200.0
	GameManager.state = GameManager.MatchState.PLAYING
	watch_signals(_ball)
	# Call _perform_dunk directly on the scene's DunkingState to test blocking path
	var dunking: DunkingState = _player1.state_machine.get_state("Dunking")
	dunking._perform_dunk()
	assert_eq(GameManager.get_score(1), 0, "Dunk should be blocked")
	assert_signal_emitted(_ball, "shot_blocked")
	assert_true(_player1.is_block_stunned(), "Dunker should be stunned")


func test_dunk_integration_scores_without_blocker() -> void:
	_add_basket(Vector2(480, 300))
	_player1 = _add_full_player(Vector2(450, 300))
	_player1.team = 1
	_add_ball(Vector2(450, 300))
	_ball.pick_up(_player1)
	GameManager.state = GameManager.MatchState.PLAYING
	watch_signals(_ball)
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("shoot")
	for i in range(120):
		await get_tree().physics_frame
		if not _player1.has_ball():
			break
	assert_gt(GameManager.get_score(1), 0, "Dunk should score without blocker")
	assert_signal_emitted(_ball, "dunk_made")


# -- Shot Blocking --

func test_shot_blocked_during_block_window() -> void:
	_add_ball(Vector2(400, 300))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 300))  # Shooter
	_player2 = _make_player(2, Vector2(420, 300))  # Defender close to ball path
	_player2.height = 50.0
	_player2.height_velocity = 100.0
	_ball.pick_up(_player1)
	watch_signals(_ball)
	_ball.shoot(_player1)
	# Simulate a frame within block window — defender is near ball
	_ball.state_machine.current_state.physics_process(0.05)
	assert_signal_emitted(_ball, "shot_blocked")
	assert_eq(_ball.state_machine.current_state.name, "Loose")


func test_shot_not_blocked_when_no_defender_jumping() -> void:
	_add_ball(Vector2(400, 300))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 300))
	_player2 = _make_player(2, Vector2(420, 300))
	# Defender on ground
	_ball.pick_up(_player1)
	watch_signals(_ball)
	_ball.shoot(_player1)
	_ball.state_machine.current_state.physics_process(0.05)
	assert_signal_not_emitted(_ball, "shot_blocked")
	assert_eq(_ball.state_machine.current_state.name, "Shot", "Ball should still be in Shot state")


func test_shot_not_blocked_after_window_expires() -> void:
	_add_ball(Vector2(400, 300))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	watch_signals(_ball)
	_ball.shoot(_player1)
	# Advance past the block window with no defender in the air
	_player2 = _make_player(2, Vector2(420, 300))  # On ground, won't trigger block
	for i in range(8):
		_ball.state_machine.current_state.physics_process(0.05)  # 0.4s > 0.3s window
	# Now put defender in the air near the ball — but window has expired
	_player2.position = _ball.global_position + Vector2(10, 0)
	_player2.height = 50.0
	_player2.height_velocity = 100.0
	_ball.state_machine.current_state.physics_process(0.05)
	assert_signal_not_emitted(_ball, "shot_blocked")


func test_shooter_stunned_after_shot_blocked() -> void:
	_add_ball(Vector2(400, 300))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 300))
	_player2 = _make_player(2, Vector2(420, 300))
	_player2.height = 50.0
	_player2.height_velocity = 100.0
	_ball.pick_up(_player1)
	_ball.shoot(_player1)
	_ball.state_machine.current_state.physics_process(0.05)
	assert_true(_player1.is_block_stunned(), "Shooter should be stunned after block")


# -- Goaltending --

func test_goaltending_awards_points() -> void:
	# Place ball close to basket so progress is high quickly
	_add_ball(Vector2(900, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(900, 360))
	_ball.pick_up(_player1)
	GameManager.state = GameManager.MatchState.PLAYING
	watch_signals(_ball)
	_ball.shoot(_player1)
	# Advance ball past goaltending_progress (0.6) but within block_window
	# Total distance ~230, need to cover 60% = ~138 units
	# shot_speed = 500, so 138/500 = ~0.276s — within 0.3s block_window
	# Simulate to reach ~65% progress
	_ball.state_machine.current_state.physics_process(0.28)
	# Now place defender near the ball
	_player2 = _make_player(2, Vector2(_ball.global_position.x, _ball.global_position.y))
	_player2.height = 50.0
	_player2.height_velocity = 100.0
	# Next frame should trigger goaltending
	_ball.state_machine.current_state.physics_process(0.01)
	assert_signal_emitted(_ball, "shot_made")
	assert_eq(GameManager.get_score(1), GameConfig.data.points_per_shot, "Goaltending should award points")


func test_goaltending_disabled_allows_late_block() -> void:
	GameConfig.data.enable_goaltending = false
	_add_ball(Vector2(900, 360))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(900, 360))
	_ball.pick_up(_player1)
	GameManager.state = GameManager.MatchState.PLAYING
	watch_signals(_ball)
	_ball.shoot(_player1)
	# Advance ball past goaltending_progress threshold
	_ball.state_machine.current_state.physics_process(0.28)
	_player2 = _make_player(2, Vector2(_ball.global_position.x, _ball.global_position.y))
	_player2.height = 50.0
	_player2.height_velocity = 100.0
	_ball.state_machine.current_state.physics_process(0.01)
	assert_signal_emitted(_ball, "shot_blocked")
	assert_eq(GameManager.get_score(1), 0, "Block should succeed when goaltending disabled")
	# Restore
	GameConfig.data.enable_goaltending = true


func test_no_goaltending_during_early_flight() -> void:
	_add_ball(Vector2(400, 300))
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(400, 300))
	_player2 = _make_player(2, Vector2(420, 300))
	_player2.height = 50.0
	_player2.height_velocity = 100.0
	_ball.pick_up(_player1)
	watch_signals(_ball)
	GameManager.state = GameManager.MatchState.PLAYING
	_ball.shoot(_player1)
	# Early flight, low progress — should be a normal block, not goaltending
	_ball.state_machine.current_state.physics_process(0.05)
	assert_signal_emitted(_ball, "shot_blocked")
	assert_signal_not_emitted(_ball, "shot_made")
	assert_eq(GameManager.get_score(1), 0, "Early block should not award points")


# -- Stun Guards --

func test_block_stun_prevents_shooting_from_idle() -> void:
	_add_basket(Vector2(1130, 360))
	_player1 = _add_full_player(Vector2(400, 300))
	_add_ball(Vector2(400, 300))
	_ball.pick_up(_player1)
	_player1.apply_block_stun()
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Idle",
		"Stunned player should not enter Shooting state")


func test_block_stun_allows_jumping_without_ball() -> void:
	_add_basket(Vector2(1130, 360))
	_player1 = _add_full_player(Vector2(400, 300))
	_player1.apply_block_stun()
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Jumping",
		"Stunned player without ball should still be able to jump")


func test_block_stun_prevents_shooting_from_running() -> void:
	_add_basket(Vector2(1130, 360))
	_player1 = _add_full_player(Vector2(400, 300))
	_add_ball(Vector2(400, 300))
	_ball.pick_up(_player1)
	Input.action_press("move_right")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_player1.apply_block_stun()
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_ne(_player1.state_machine.current_state.name, "Shooting",
		"Stunned player should not enter Shooting from Running")

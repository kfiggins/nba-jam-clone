extends GutTest

var _ball: Ball
var _player1: Player  # AI player (team 1)
var _player2: Player  # Opponent or teammate
var _player3: Player  # Extra player when needed
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
	for p in [_player1, _player2, _player3]:
		if p:
			p.process_mode = Node.PROCESS_MODE_DISABLED
			p.remove_from_group("players")
			p.queue_free()
	_player1 = null
	_player2 = null
	_player3 = null
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


func _make_ai_controller(p: Player) -> AIController:
	# Add as child of the player so _ready() finds the correct parent
	var c := AIController.new()
	c.name = "AIController"
	p.add_child(c)
	return c


func _add_full_player(pos: Vector2 = Vector2(400, 300), team_id: int = 1, human: bool = false) -> Player:
	var p: Player = load("res://scenes/player/player.tscn").instantiate()
	p.position = pos
	p.team = team_id
	p.is_human = human
	add_child(p)
	return p


# ============================================================
# Config Tests
# ============================================================

func test_ai_shoot_range_config() -> void:
	assert_eq(GameConfig.data.ai_shoot_range, 250.0)


func test_ai_open_threshold_config() -> void:
	assert_eq(GameConfig.data.ai_open_threshold, 60.0)


func test_ai_block_react_range_config() -> void:
	assert_eq(GameConfig.data.ai_block_react_range, 80.0)


# ============================================================
# Player AI Flags
# ============================================================

func test_ai_flags_default_to_false() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	assert_false(_player1.ai_shoot_requested)
	assert_false(_player1.ai_pass_requested)
	assert_false(_player1.ai_steal_requested)
	assert_false(_player1.ai_sprint_requested)


func test_ai_flags_can_be_set() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	_player1.ai_shoot_requested = true
	_player1.ai_pass_requested = true
	_player1.ai_steal_requested = true
	_player1.ai_sprint_requested = true
	assert_true(_player1.ai_shoot_requested)
	assert_true(_player1.ai_pass_requested)
	assert_true(_player1.ai_steal_requested)
	assert_true(_player1.ai_sprint_requested)


func test_ai_sprint_increases_speed() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	_player1.turbo = 100.0
	var normal_speed := _player1.get_move_speed()
	_player1.ai_sprint_requested = true
	var sprint_speed := _player1.get_move_speed()
	assert_gt(sprint_speed, normal_speed, "AI sprint should increase speed")
	assert_eq(sprint_speed, GameConfig.data.player_sprint_speed)


func test_ai_is_sprinting_when_flagged() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	_player1.turbo = 100.0
	assert_false(_player1.is_sprinting())
	_player1.ai_sprint_requested = true
	assert_true(_player1.is_sprinting())


# ============================================================
# State Integration: Idle
# ============================================================

func test_idle_ai_shoot_with_ball_transitions_to_shooting() -> void:
	_add_ball()
	_add_basket()
	_player1 = _add_full_player(Vector2(400, 300), 1, false)
	_ball.pick_up(_player1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_player1.ai_shoot_requested = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Shooting")


func test_idle_ai_shoot_without_ball_transitions_to_jumping() -> void:
	_add_ball(Vector2(900, 900))  # far away to prevent auto-pickup
	_player1 = _add_full_player(Vector2(400, 300), 1, false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_player1.ai_shoot_requested = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Jumping")


func test_idle_ai_shoot_in_dunk_range_transitions_to_dunking() -> void:
	_add_ball()
	_add_basket(Vector2(500, 300))
	_player1 = _add_full_player(Vector2(460, 300), 1, false)
	_ball.pick_up(_player1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_player1.ai_shoot_requested = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Dunking")


func test_idle_ai_pass_with_ball_triggers_pass() -> void:
	_add_ball()
	_player1 = _add_full_player(Vector2(400, 300), 1, false)
	_player2 = _add_full_player(Vector2(500, 300), 1, false)
	_ball.pick_up(_player1)
	watch_signals(_ball)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_player1.ai_pass_requested = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_signal_emitted(_ball, "ball_passed")


# ============================================================
# State Integration: Running
# ============================================================

func test_running_ai_shoot_with_ball_transitions_to_shooting() -> void:
	_add_ball()
	_add_basket()
	_player1 = _add_full_player(Vector2(400, 300), 1, false)
	_ball.pick_up(_player1)
	_player1.input_direction = Vector2.RIGHT
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Running")
	_player1.ai_shoot_requested = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Shooting")


func test_running_ai_shoot_without_ball_transitions_to_jumping() -> void:
	_add_ball(Vector2(900, 900))  # far away to prevent auto-pickup
	_player1 = _add_full_player(Vector2(400, 300), 1, false)
	_player1.input_direction = Vector2.RIGHT
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Running")
	_player1.ai_shoot_requested = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player1.state_machine.current_state.name, "Jumping")


func test_running_ai_steal_triggers_steal_attempt() -> void:
	_add_ball()
	_player1 = _add_full_player(Vector2(410, 300), 1, false)
	_player2 = _add_full_player(Vector2(400, 300), 2, false)
	_ball.pick_up(_player2)
	_player1.input_direction = Vector2.RIGHT
	watch_signals(_ball)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_player1.ai_steal_requested = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	# Steal was attempted (either succeeded or failed)
	var stolen: int = get_signal_emit_count(_ball, "ball_stolen")
	var failed: int = get_signal_emit_count(_ball, "steal_failed")
	assert_gt(stolen + failed, 0, "Steal attempt should have been made")


# ============================================================
# AIController Initialization
# ============================================================

func test_ai_controller_finds_parent_player() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	var controller := AIController.new()
	controller.name = "AIController"
	_player1.add_child(controller)
	assert_eq(controller.player, _player1)


func test_ai_controller_inactive_for_human() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(100, 100), true)  # human
	var controller := _make_ai_controller(_player1)
	controller._evaluate()
	assert_false(_player1.ai_shoot_requested)
	assert_false(_player1.ai_pass_requested)
	assert_false(_player1.ai_steal_requested)


func test_ai_controller_inactive_when_not_playing() -> void:
	_add_ball()
	_add_basket()
	_player1 = _make_player(1, Vector2(100, 100))
	var controller := _make_ai_controller(_player1)
	GameManager.state = GameManager.MatchState.PREGAME
	controller._physics_process(0.5)
	assert_eq(_player1.input_direction, Vector2.ZERO)


# ============================================================
# AIController Offense (with ball)
# ============================================================

func test_ai_shoots_in_dunk_range() -> void:
	_add_ball()
	_add_basket(Vector2(500, 300))
	_player1 = _make_player(1, Vector2(460, 300))
	_ball.pick_up(_player1)
	var controller := _make_ai_controller(_player1)
	controller._evaluate()
	assert_true(_player1.ai_shoot_requested, "AI should request shoot in dunk range")


func test_ai_shoots_when_close_and_open() -> void:
	_add_ball()
	_add_basket(Vector2(500, 300))
	# AI close to basket, defenders far away
	_player1 = _make_player(1, Vector2(350, 300))
	_ball.pick_up(_player1)
	_player2 = _make_player(2, Vector2(100, 100))  # far defender
	var controller := _make_ai_controller(_player1)
	controller._evaluate()
	assert_true(_player1.ai_shoot_requested, "AI should shoot when close and open")


func test_ai_passes_to_better_positioned_teammate() -> void:
	_add_ball()
	_add_basket(Vector2(500, 300))
	# AI far from basket
	_player1 = _make_player(1, Vector2(200, 300))
	_ball.pick_up(_player1)
	# Teammate much closer to basket
	_player2 = _make_player(1, Vector2(420, 300))
	# Defender far
	_player3 = _make_player(2, Vector2(100, 100))
	# Set aggression to 0 so AI won't randomly shoot
	GameConfig.data.ai_aggression = 0.0
	var controller := _make_ai_controller(_player1)
	controller._evaluate()
	assert_true(_player1.ai_pass_requested, "AI should pass to better positioned teammate")
	GameConfig.data.ai_aggression = 0.5


func test_ai_moves_toward_basket_when_far() -> void:
	_add_ball()
	_add_basket(Vector2(1130, 360))
	_player1 = _make_player(1, Vector2(200, 360))
	_ball.pick_up(_player1)
	# Defenders far
	_player2 = _make_player(2, Vector2(100, 100))
	# Set aggression to 0 so AI won't randomly shoot
	GameConfig.data.ai_aggression = 0.0
	var controller := _make_ai_controller(_player1)
	controller._evaluate()
	# AI should move toward basket (positive x direction)
	assert_gt(_player1.input_direction.x, 0.0, "AI should move toward basket")
	assert_false(_player1.ai_shoot_requested, "Too far to shoot")
	GameConfig.data.ai_aggression = 0.5


# ============================================================
# AIController Defense
# ============================================================

func test_ai_jumps_to_block_shooting_opponent() -> void:
	_add_ball()
	_add_basket()
	# Opponent with ball
	_player2 = _make_player(2, Vector2(400, 300))
	_ball.pick_up(_player2)
	# Simulate opponent in Shooting state by adding a fake state node
	var fake_state := State.new()
	fake_state.name = "Shooting"
	_player2.state_machine.add_child(fake_state)
	_player2.state_machine._index_states()
	_player2.state_machine.current_state = fake_state
	# AI defender close enough
	_player1 = _make_player(1, Vector2(430, 300))
	var controller := _make_ai_controller(_player1)
	controller._evaluate()
	assert_true(_player1.ai_shoot_requested, "AI should jump to block")


func test_ai_steals_when_close_to_handler() -> void:
	_add_ball()
	_add_basket()
	_player2 = _make_player(2, Vector2(400, 300))
	_ball.pick_up(_player2)
	_player1 = _make_player(1, Vector2(420, 300))
	GameConfig.data.ai_aggression = 1.0  # guarantee steal attempt
	var controller := _make_ai_controller(_player1)
	controller._evaluate()
	assert_true(_player1.ai_steal_requested, "AI should attempt steal when close")
	GameConfig.data.ai_aggression = 0.5


func test_ai_guards_ball_handler() -> void:
	_add_ball()
	_add_basket(Vector2(1130, 360))
	# Handler on offense
	_player2 = _make_player(2, Vector2(600, 360))
	_ball.pick_up(_player2)
	# AI defender between handler and basket (not beaten), too far to steal
	_player1 = _make_player(1, Vector2(800, 360))
	GameConfig.data.ai_aggression = 0.0  # prevent steal
	var controller := _make_ai_controller(_player1)
	controller._evaluate()
	# Should move toward handler (negative x since handler is to the left)
	assert_lt(_player1.input_direction.x, 0.0, "AI should move toward handler")
	assert_false(_player1.ai_steal_requested)
	GameConfig.data.ai_aggression = 0.5


func test_ai_recovers_toward_basket_when_beaten() -> void:
	_add_ball()
	_add_basket(Vector2(1130, 360))
	# Handler close to basket, AI far behind
	_player2 = _make_player(2, Vector2(1000, 360))
	_ball.pick_up(_player2)
	_player1 = _make_player(1, Vector2(400, 360))
	var controller := _make_ai_controller(_player1)
	controller._evaluate()
	# Should move toward basket (positive x)
	assert_gt(_player1.input_direction.x, 0.0, "AI should recover toward basket")
	assert_true(_player1.ai_sprint_requested, "AI should sprint when recovering")


# ============================================================
# AIController Loose Ball & Offense Without Ball
# ============================================================

func test_ai_chases_loose_ball() -> void:
	_add_ball(Vector2(600, 300))
	_player1 = _make_player(1, Vector2(200, 300))
	var controller := _make_ai_controller(_player1)
	controller._evaluate()
	# Ball is to the right
	assert_gt(_player1.input_direction.x, 0.0, "AI should chase loose ball")
	assert_true(_player1.ai_sprint_requested)


func test_ai_moves_to_scoring_position_without_ball() -> void:
	_add_ball()
	_add_basket(Vector2(1130, 360))
	# Teammate has ball
	_player2 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player2)
	# AI without ball, far from basket
	_player1 = _make_player(1, Vector2(200, 300))
	var controller := _make_ai_controller(_player1)
	controller._evaluate()
	# Should move toward basket area (positive x)
	assert_gt(_player1.input_direction.x, 0.0, "AI should move toward scoring position")

extends GutTest

var _ball: Ball
var _player1: Player  # Defender / stealer (team 1)
var _player2: Player  # Ball handler (team 2)
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
	_manager.queue_free()
	_config.queue_free()


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


# ============================================================
# Config Tests
# ============================================================

func test_steal_facing_bonus_config() -> void:
	assert_eq(GameConfig.data.steal_facing_bonus, 0.25)


func test_steal_facing_penalty_config() -> void:
	assert_eq(GameConfig.data.steal_facing_penalty, -0.15)


func test_steal_distance_max_bonus_config() -> void:
	assert_eq(GameConfig.data.steal_distance_max_bonus, 0.15)


func test_bump_speed_reduction_config() -> void:
	assert_eq(GameConfig.data.bump_speed_reduction, 0.4)


func test_bump_duration_config() -> void:
	assert_eq(GameConfig.data.bump_duration, 0.3)


func test_bump_cooldown_config() -> void:
	assert_eq(GameConfig.data.bump_cooldown, 0.5)


func test_enable_auto_face_config() -> void:
	assert_eq(GameConfig.data.enable_auto_face_ball_handler, true)


# ============================================================
# Steal Chance Calculation
# ============================================================

func test_steal_chance_base_at_max_range_side_approach() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(400, 300))
	_player2.facing_direction = Vector2.RIGHT
	_ball.pick_up(_player2)
	# Stealer perpendicular to handler (side approach at max range)
	_player1 = _make_player(1, Vector2(400, 300 + GameConfig.data.steal_range))
	_player1.facing_direction = Vector2.DOWN
	var chance: float = _ball._calculate_steal_chance(_player1)
	# Side approach: dot ~= 0, distance at max => bonus ~= 0
	assert_almost_eq(chance, GameConfig.data.steal_chance_base, 0.05)


func test_steal_chance_higher_when_close() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(400, 300))
	_player2.facing_direction = Vector2.UP  # perpendicular
	_ball.pick_up(_player2)
	# Stealer at same position (dist = 0, side approach)
	_player1 = _make_player(1, Vector2(400, 301))
	var chance: float = _ball._calculate_steal_chance(_player1)
	assert_gt(chance, GameConfig.data.steal_chance_base, "Close range should give bonus")


func test_steal_chance_higher_from_behind() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(400, 300))
	_player2.facing_direction = Vector2.RIGHT  # facing right
	_ball.pick_up(_player2)
	# Stealer behind handler (to the left)
	_player1 = _make_player(1, Vector2(380, 300))
	var chance: float = _ball._calculate_steal_chance(_player1)
	assert_gt(chance, GameConfig.data.steal_chance_base, "Behind approach should give bonus")


func test_steal_chance_lower_head_on() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(400, 300))
	_player2.facing_direction = Vector2.RIGHT  # facing right
	_ball.pick_up(_player2)
	# Stealer in front of handler (to the right, at mid range)
	_player1 = _make_player(1, Vector2(420, 300))
	var chance: float = _ball._calculate_steal_chance(_player1)
	assert_lt(chance, GameConfig.data.steal_chance_base, "Head-on should give penalty")


func test_steal_chance_max_from_behind_point_blank() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(400, 300))
	_player2.facing_direction = Vector2.RIGHT
	_ball.pick_up(_player2)
	# Stealer directly behind, point blank
	_player1 = _make_player(1, Vector2(399, 300))
	var chance: float = _ball._calculate_steal_chance(_player1)
	var expected := GameConfig.data.steal_chance_base + GameConfig.data.steal_distance_max_bonus + GameConfig.data.steal_facing_bonus
	assert_almost_eq(chance, expected, 0.05)


func test_steal_chance_min_head_on_max_range() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(400, 300))
	_player2.facing_direction = Vector2.RIGHT
	_ball.pick_up(_player2)
	# Stealer directly in front at max steal range
	_player1 = _make_player(1, Vector2(400 + GameConfig.data.steal_range, 300))
	var chance: float = _ball._calculate_steal_chance(_player1)
	# Distance bonus = 0 (at max range), facing penalty = steal_facing_penalty * 1.0
	var expected := GameConfig.data.steal_chance_base + GameConfig.data.steal_facing_penalty
	assert_almost_eq(chance, expected, 0.05)


func test_steal_chance_clamped_at_minimum() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(400, 300))
	_player2.facing_direction = Vector2.RIGHT
	_ball.pick_up(_player2)
	_player1 = _make_player(1, Vector2(400 + GameConfig.data.steal_range, 300))
	# Temporarily lower base to force clamping
	var orig := GameConfig.data.steal_chance_base
	GameConfig.data.steal_chance_base = 0.0
	var chance: float = _ball._calculate_steal_chance(_player1)
	assert_gte(chance, 0.05, "Chance should never drop below 0.05")
	GameConfig.data.steal_chance_base = orig


# ============================================================
# Steal Stun
# ============================================================

func test_steal_stun_starts_at_zero() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	assert_eq(_player1.steal_stun_timer, 0.0)


func test_apply_steal_stun_sets_timer() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	_player1.apply_steal_stun()
	assert_eq(_player1.steal_stun_timer, GameConfig.data.steal_stun_duration)


func test_is_steal_stunned_true_after_stun() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	assert_false(_player1.is_steal_stunned())
	_player1.apply_steal_stun()
	assert_true(_player1.is_steal_stunned())


func test_steal_stun_prevents_steal_attempt() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(400, 300))
	_ball.pick_up(_player2)
	_player1 = _make_player(1, Vector2(410, 300))
	_player1.apply_steal_stun()
	watch_signals(_ball)
	_player1.try_steal()
	# Steal should not even be attempted
	assert_signal_not_emitted(_ball, "ball_stolen")
	assert_signal_not_emitted(_ball, "steal_failed")


func test_steal_stun_timer_decreases_over_time() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	_player1.apply_steal_stun()
	var initial := _player1.steal_stun_timer
	_player1._physics_process(0.1)
	assert_lt(_player1.steal_stun_timer, initial)


# ============================================================
# Body Bump
# ============================================================

func test_bump_slow_starts_at_zero() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	assert_eq(_player1.bump_slow_timer, 0.0)


func test_apply_bump_sets_timer() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	_player1.apply_bump()
	assert_eq(_player1.bump_slow_timer, GameConfig.data.bump_duration)


func test_is_bumped_true_after_bump() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	assert_false(_player1.is_bumped())
	_player1.apply_bump()
	assert_true(_player1.is_bumped())


func test_bumped_player_has_reduced_speed() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	var normal_speed := _player1.get_move_speed()
	_player1.apply_bump()
	var bumped_speed := _player1.get_move_speed()
	assert_lt(bumped_speed, normal_speed, "Bumped player should be slower")
	var expected := normal_speed * GameConfig.data.bump_speed_reduction
	assert_almost_eq(bumped_speed, expected, 0.01)


func test_bump_speed_returns_to_normal() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	var normal_speed := _player1.get_move_speed()
	_player1.apply_bump()
	# Tick past the bump duration
	_player1._physics_process(GameConfig.data.bump_duration + 0.1)
	assert_false(_player1.is_bumped())
	assert_eq(_player1.get_move_speed(), normal_speed)


func test_bump_cooldown_timer() -> void:
	_player1 = _make_player(1, Vector2(100, 100))
	assert_eq(_player1.bump_cooldown_timer, 0.0)
	_player1.bump_cooldown_timer = GameConfig.data.bump_cooldown
	_player1._physics_process(0.1)
	assert_almost_eq(_player1.bump_cooldown_timer, GameConfig.data.bump_cooldown - 0.1, 0.01)


# ============================================================
# Auto-Face Ball Handler
# ============================================================

func test_auto_face_turns_toward_opponent_handler() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(500, 300))
	_ball.pick_up(_player2)
	# Defender on team 1 facing right, handler is to the right
	_player1 = _make_player(1, Vector2(300, 300))
	_player1.facing_direction = Vector2.UP  # initially facing up
	_player1.auto_face_ball_handler()
	# Should now face toward player2 (to the right)
	assert_gt(_player1.facing_direction.x, 0.0, "Should face toward handler (right)")
	assert_almost_eq(_player1.facing_direction.y, 0.0, 0.01)


func test_auto_face_does_nothing_when_has_ball() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(300, 300))
	_ball.pick_up(_player1)
	_player1.facing_direction = Vector2.UP
	# Even if there's an opponent handler, having ball should prevent auto-face
	_player1.auto_face_ball_handler()
	assert_eq(_player1.facing_direction, Vector2.UP, "Should not change facing when has ball")


func test_auto_face_does_nothing_when_disabled() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(500, 300))
	_ball.pick_up(_player2)
	_player1 = _make_player(1, Vector2(300, 300))
	_player1.facing_direction = Vector2.UP
	GameConfig.data.enable_auto_face_ball_handler = false
	_player1.auto_face_ball_handler()
	assert_eq(_player1.facing_direction, Vector2.UP, "Should not change facing when disabled")
	GameConfig.data.enable_auto_face_ball_handler = true


func test_auto_face_ignores_same_team_handler() -> void:
	_add_ball()
	# Handler is on same team as defender
	_player2 = _make_player(1, Vector2(500, 300))
	_ball.pick_up(_player2)
	_player1 = _make_player(1, Vector2(300, 300))
	_player1.facing_direction = Vector2.UP
	_player1.auto_face_ball_handler()
	assert_eq(_player1.facing_direction, Vector2.UP, "Should not face same-team handler")


# ============================================================
# Integration: Failed Steal Applies Stun
# ============================================================

func test_failed_steal_applies_stun() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(400, 300))
	_ball.pick_up(_player2)
	_player1 = _make_player(1, Vector2(410, 300))
	# Force near-zero chance and seed RNG for deterministic failure
	GameConfig.data.steal_chance_base = 0.0
	GameConfig.data.steal_facing_bonus = 0.0
	GameConfig.data.steal_distance_max_bonus = 0.0
	seed(42)
	_player1.try_steal()
	assert_true(_player1.is_steal_stunned(), "Failed steal should apply stun")
	# Restore
	GameConfig.data.steal_chance_base = 0.3
	GameConfig.data.steal_facing_bonus = 0.25
	GameConfig.data.steal_distance_max_bonus = 0.15


func test_successful_steal_with_high_chance() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(400, 300))
	_ball.pick_up(_player2)
	_player1 = _make_player(1, Vector2(410, 300))
	# Force guaranteed success
	GameConfig.data.steal_chance_base = 1.0
	watch_signals(_ball)
	_player1.try_steal()
	assert_signal_emitted(_ball, "ball_stolen")
	assert_eq(_ball.current_owner, _player1)
	assert_false(_player1.is_steal_stunned(), "Successful steal should not stun")
	GameConfig.data.steal_chance_base = 0.3


func test_steal_failed_signal_emitted() -> void:
	_add_ball()
	_player2 = _make_player(2, Vector2(400, 300))
	_ball.pick_up(_player2)
	_player1 = _make_player(1, Vector2(410, 300))
	GameConfig.data.steal_chance_base = 0.0
	GameConfig.data.steal_facing_bonus = 0.0
	GameConfig.data.steal_distance_max_bonus = 0.0
	watch_signals(_ball)
	seed(42)
	_player1.try_steal()
	assert_signal_emitted(_ball, "steal_failed")
	GameConfig.data.steal_chance_base = 0.3
	GameConfig.data.steal_facing_bonus = 0.25
	GameConfig.data.steal_distance_max_bonus = 0.15

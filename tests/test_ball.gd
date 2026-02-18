extends GutTest

var _ball: Ball
var _player1: Player
var _player2: Player
var _opponent: Player
var _config: Node


func before_each() -> void:
	_config = load("res://scripts/autoload/game_config.gd").new()
	_config.name = "GameConfig"
	add_child(_config)


func after_each() -> void:
	# Remove from groups immediately to prevent stale group queries in next test
	for p in [_player1, _player2, _opponent]:
		if p:
			p.remove_from_group("players")
			p.queue_free()
	_player1 = null
	_player2 = null
	_opponent = null
	if _ball:
		_ball.remove_from_group("ball")
		_ball.queue_free()
		_ball = null
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
	_ball.add_child(sm)
	_ball.add_to_group("ball")
	add_child(_ball)


# -- Ownership --

func test_ball_starts_with_no_owner() -> void:
	_add_ball()
	assert_null(_ball.current_owner)


func test_pick_up_sets_owner() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	assert_eq(_ball.current_owner, _player1)


func test_pick_up_sets_held_ball_on_player() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	assert_eq(_player1.held_ball, _ball)


func test_release_clears_owner() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	_ball.release()
	assert_null(_ball.current_owner)


func test_release_clears_held_ball_on_player() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	_ball.release()
	assert_null(_player1.held_ball)


func test_owner_changed_signal_on_pickup() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(400, 300))
	watch_signals(_ball)
	_ball.pick_up(_player1)
	assert_signal_emitted(_ball, "owner_changed")


func test_owner_changed_signal_on_release() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	watch_signals(_ball)
	_ball.release()
	assert_signal_emitted(_ball, "owner_changed")


# -- Ball Gravity --

func test_gravity_reduces_height() -> void:
	_add_ball()
	_ball.height = 100.0
	_ball.height_velocity = 0.0
	_ball.apply_ball_gravity(0.1)
	assert_lt(_ball.height, 100.0, "Gravity should reduce height")


func test_ball_bounces_at_ground() -> void:
	_add_ball()
	_ball.height = 5.0
	_ball.height_velocity = -200.0
	_ball.apply_ball_gravity(0.1)
	assert_gt(_ball.height_velocity, 0.0, "Should bounce upward")


func test_ball_stops_bouncing_when_slow() -> void:
	_add_ball()
	_ball.height = 0.001
	_ball.height_velocity = -30.0
	_ball.apply_ball_gravity(0.001)
	assert_eq(_ball.height_velocity, 0.0, "Should stop when velocity too low")


func test_bounce_signal() -> void:
	_add_ball()
	watch_signals(_ball)
	_ball.height = 5.0
	_ball.height_velocity = -200.0
	_ball.apply_ball_gravity(0.1)
	assert_signal_emitted(_ball, "ball_bounced")


func test_bounce_factor_reduces_velocity() -> void:
	_add_ball()
	_ball.height = 5.0
	_ball.height_velocity = -200.0
	_ball.apply_ball_gravity(0.1)
	# Bounce velocity should be less than original (bounce_factor = 0.6)
	assert_lt(_ball.height_velocity, 200.0, "Bounce should lose energy")


# -- Visual Height --

func test_sprite_offset_matches_height() -> void:
	_add_ball()
	_ball.height = 50.0
	_ball._update_visual_height()
	assert_eq(_ball.sprite.position.y, -50.0)


func test_shadow_stays_at_ground() -> void:
	_add_ball()
	_ball.height = 50.0
	_ball._update_visual_height()
	assert_eq(_ball.shadow.position.y, 0.0)


# -- Player has_ball --

func test_player_has_ball_false_by_default() -> void:
	_player1 = _make_player(1, Vector2.ZERO)
	assert_false(_player1.has_ball())


func test_player_has_ball_true_after_pickup() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	assert_true(_player1.has_ball())


func test_player_has_ball_false_after_release() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	_ball.release()
	assert_false(_player1.has_ball())


# -- Pass Target --

func test_find_pass_target_returns_teammate() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(100, 100))
	_player2 = _make_player(1, Vector2(200, 100))
	var target := _ball.find_pass_target(_player1)
	assert_eq(target, _player2)


func test_find_pass_target_ignores_opponents() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(100, 100))
	_opponent = _make_player(2, Vector2(150, 100))
	var target := _ball.find_pass_target(_player1)
	assert_null(target, "Should not target opponents")


func test_find_pass_target_returns_nearest() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(100, 100))
	_player2 = _make_player(1, Vector2(200, 100))
	_opponent = _make_player(1, Vector2(500, 100))
	var target := _ball.find_pass_target(_player1)
	assert_eq(target, _player2, "Should pick nearest teammate")


func test_find_pass_target_no_teammates() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(100, 100))
	var target := _ball.find_pass_target(_player1)
	assert_null(target, "No teammate available")


# -- Pass --

func test_start_pass_emits_signal() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(100, 100))
	_player2 = _make_player(1, Vector2(300, 100))
	_ball.pick_up(_player1)
	watch_signals(_ball)
	_ball.start_pass(_player1, _player2)
	assert_signal_emitted(_ball, "ball_passed")


func test_start_pass_clears_owner() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(100, 100))
	_player2 = _make_player(1, Vector2(300, 100))
	_ball.pick_up(_player1)
	_ball.start_pass(_player1, _player2)
	assert_null(_ball.current_owner)


func test_start_pass_sets_target() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(100, 100))
	_player2 = _make_player(1, Vector2(300, 100))
	_ball.pick_up(_player1)
	_ball.start_pass(_player1, _player2)
	assert_eq(_ball.pass_target, _player2)


# -- Steal --

func test_steal_cooldown_starts_at_zero() -> void:
	_player1 = _make_player(1, Vector2.ZERO)
	assert_eq(_player1.steal_cooldown_timer, 0.0)


func test_try_steal_sets_cooldown() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(100, 100))
	_opponent = _make_player(2, Vector2(100, 100))
	_ball.pick_up(_opponent)
	_player1.try_steal()
	assert_gt(_player1.steal_cooldown_timer, 0.0, "Steal should trigger cooldown")


func test_try_steal_blocked_by_cooldown() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(100, 100))
	_opponent = _make_player(2, Vector2(100, 100))
	_ball.pick_up(_opponent)
	_player1.steal_cooldown_timer = 1.0
	_player1.try_steal()
	# Cooldown should still be 1.0 (not reset), meaning steal didn't execute
	assert_eq(_player1.steal_cooldown_timer, 1.0, "Should not steal while on cooldown")


func test_try_steal_requires_range() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(0, 0))
	_opponent = _make_player(2, Vector2(500, 500))
	_ball.pick_up(_opponent)
	_player1.try_steal()
	# Steal was attempted (cooldown set) but too far away
	assert_gt(_player1.steal_cooldown_timer, 0.0)
	# Opponent should still have ball (too far for steal)
	assert_eq(_ball.current_owner, _opponent, "Opponent too far, should keep ball")


func test_cannot_steal_from_own_team() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(100, 100))
	_player2 = _make_player(1, Vector2(100, 100))
	_ball.pick_up(_player2)
	_player1.try_steal()
	assert_eq(_ball.current_owner, _player2, "Cannot steal from teammate")


func test_attempt_steal_fails_on_same_team() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(100, 100))
	_player2 = _make_player(1, Vector2(100, 100))
	_ball.pick_up(_player2)
	var result := _ball.attempt_steal(_player1)
	assert_false(result, "Should not steal from same team")


# -- Release with velocity --

func test_release_with_velocity() -> void:
	_add_ball()
	_player1 = _make_player(1, Vector2(400, 300))
	_ball.pick_up(_player1)
	_ball.release(Vector2(100.0, 0.0), 50.0)
	assert_eq(_ball.ground_velocity, Vector2(100.0, 0.0))
	assert_eq(_ball.height_velocity, 50.0)


# -- Intercept --

func test_check_intercept_finds_opponent() -> void:
	_add_ball(Vector2(200, 100))
	_player1 = _make_player(1, Vector2(100, 100))
	_player2 = _make_player(1, Vector2(300, 100))
	_opponent = _make_player(2, Vector2(200, 100))
	_ball.pass_target = _player2
	var interceptor := _ball.check_intercept()
	assert_eq(interceptor, _opponent)


func test_check_intercept_ignores_target() -> void:
	_add_ball(Vector2(300, 100))
	_player1 = _make_player(1, Vector2(100, 100))
	_player2 = _make_player(1, Vector2(300, 100))
	_ball.pass_target = _player2
	var interceptor := _ball.check_intercept()
	assert_null(interceptor, "Should not intercept own target")


func test_check_intercept_ignores_same_team() -> void:
	_add_ball(Vector2(200, 100))
	_player1 = _make_player(1, Vector2(100, 100))
	_player2 = _make_player(1, Vector2(300, 100))
	# Third teammate near ball — use _opponent slot for cleanup
	_opponent = _make_player(1, Vector2(200, 100))
	_ball.pass_target = _player2
	var interceptor := _ball.check_intercept()
	assert_null(interceptor, "Same-team player should not intercept")

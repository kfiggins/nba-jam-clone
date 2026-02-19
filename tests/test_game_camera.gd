extends GutTest

var _camera: GameCamera
var _ball: Node2D
var _basket: Node2D
var _config: Node
var _manager: Node
var _players: Array[Node2D] = []


func before_each() -> void:
	_config = load("res://scripts/autoload/game_config.gd").new()
	_config.name = "GameConfig"
	add_child(_config)
	_manager = load("res://scripts/autoload/game_manager.gd").new()
	_manager.name = "GameManager"
	add_child(_manager)
	_camera = GameCamera.new()
	_camera.position = Vector2(640, 360)
	add_child(_camera)


func after_each() -> void:
	if _camera:
		_camera.queue_free()
		_camera = null
	if _ball:
		_ball.remove_from_group("ball")
		_ball.queue_free()
		_ball = null
	for p in _players:
		if p:
			p.remove_from_group("players")
			p.queue_free()
	_players.clear()
	if _basket:
		_basket.remove_from_group("basket")
		_basket.queue_free()
		_basket = null
	_manager.queue_free()
	_config.queue_free()


# -- Helpers --

func _add_ball(pos: Vector2 = Vector2(640, 360)) -> void:
	_ball = Node2D.new()
	_ball.position = pos
	_ball.add_to_group("ball")
	add_child(_ball)


func _add_basket(pos: Vector2 = Vector2(1130, 360)) -> void:
	_basket = Node2D.new()
	_basket.position = pos
	_basket.add_to_group("basket")
	add_child(_basket)


func _add_player(pos: Vector2) -> Node2D:
	var p := Node2D.new()
	p.position = pos
	p.add_to_group("players")
	add_child(p)
	_players.append(p)
	return p


# =============================================================================
# Config tests
# =============================================================================

func test_config_camera_smooth_speed() -> void:
	assert_eq(GameConfig.data.camera_smooth_speed, 5.0)

func test_config_camera_zoom_base() -> void:
	assert_eq(GameConfig.data.camera_zoom_base, 1.0)

func test_config_camera_zoom_action() -> void:
	assert_eq(GameConfig.data.camera_zoom_action, 1.15)

func test_config_camera_action_range() -> void:
	assert_eq(GameConfig.data.camera_action_range, 200.0)

func test_config_camera_zoom_smooth_speed() -> void:
	assert_eq(GameConfig.data.camera_zoom_smooth_speed, 3.0)

func test_config_camera_offset_x() -> void:
	assert_eq(GameConfig.data.camera_offset_x, 50.0)


# =============================================================================
# Initialization tests
# =============================================================================

func test_camera_limits_set() -> void:
	assert_eq(_camera.limit_left, 0)
	assert_eq(_camera.limit_right, 1280)
	assert_eq(_camera.limit_top, 0)
	assert_eq(_camera.limit_bottom, 720)

func test_camera_is_enabled() -> void:
	assert_true(_camera.enabled)


# =============================================================================
# Target calculation tests
# =============================================================================

func test_target_no_ball_returns_center() -> void:
	var target := _camera._get_target_position()
	assert_eq(target, Vector2(640, 360))

func test_target_follows_ball_position() -> void:
	_add_ball(Vector2(800, 400))
	_add_basket(Vector2(1130, 360))
	var target := _camera._get_target_position()
	# Target should be shifted toward ball (right side)
	assert_gt(target.x, 640.0, "Target should shift right toward ball")

func test_target_includes_nearby_players() -> void:
	_add_ball(Vector2(600, 360))
	_add_basket(Vector2(1130, 360))
	_add_player(Vector2(400, 360))
	var target_with_player := _camera._get_target_position()
	# Player at 400 pulls focus left compared to just ball at 600
	_players[0].position = Vector2(600, 360)
	var target_player_at_ball := _camera._get_target_position()
	assert_lt(target_with_player.x, target_player_at_ball.x,
		"Player left of ball should pull target left")

func test_target_biases_toward_basket() -> void:
	_add_ball(Vector2(200, 360))
	_add_basket(Vector2(1130, 360))
	var target := _camera._get_target_position()
	# Basket at 1130 should pull target right from ball at 200
	# Pure ball pos would be ~200, but basket blend + offset pulls right
	assert_gt(target.x, 200.0, "Target should be pulled toward basket")

func test_target_offset_x_applied() -> void:
	_add_ball(Vector2(640, 360))
	_add_basket(Vector2(1130, 360))
	var target := _camera._get_target_position()
	# Ball at center, basket at 1130 — target includes offset_x (50)
	# focus = ball (640,360), blended = 640*0.7 + 1130*0.3 = 787, + 50 = 837
	assert_gt(target.x, 800.0, "Offset should push target toward basket side")

func test_target_basket_default_when_no_basket_node() -> void:
	_add_ball(Vector2(640, 360))
	# No basket added — should use fallback position (1130, 360)
	var target := _camera._get_target_position()
	assert_gt(target.x, 640.0, "Should still bias toward default basket position")


# =============================================================================
# Smooth follow tests
# =============================================================================

func test_camera_moves_toward_target() -> void:
	_add_ball(Vector2(900, 400))
	_add_basket(Vector2(1130, 360))
	var start_pos := _camera.global_position
	_camera._physics_process(0.016)
	var new_pos := _camera.global_position
	var target := _camera._get_target_position()
	# Camera should have moved closer to target
	assert_lt(new_pos.distance_to(target), start_pos.distance_to(target),
		"Camera should move closer to target")

func test_camera_does_not_teleport() -> void:
	_add_ball(Vector2(1100, 300))
	_add_basket(Vector2(1130, 360))
	var start_pos := _camera.global_position
	_camera._physics_process(0.016)
	var moved := _camera.global_position.distance_to(start_pos)
	var total := start_pos.distance_to(_camera._get_target_position())
	assert_lt(moved, total, "Camera should not teleport to target in one frame")

func test_camera_reaches_target_over_time() -> void:
	_add_ball(Vector2(800, 400))
	_add_basket(Vector2(1130, 360))
	var target := _camera._get_target_position()
	for i in range(300):
		_camera._physics_process(0.016)
	var dist := _camera.global_position.distance_to(target)
	assert_lt(dist, 5.0, "Camera should reach target after many frames")


# =============================================================================
# Zoom tests
# =============================================================================

func test_zoom_increases_near_basket() -> void:
	_add_ball(Vector2(1080, 360))  # Within 200px of basket at 1130
	_add_basket(Vector2(1130, 360))
	_camera.zoom = Vector2(1.0, 1.0)
	for i in range(60):
		_camera._update_zoom(0.016)
	assert_gt(_camera.zoom.x, 1.0, "Zoom should increase near basket")

func test_zoom_stays_base_when_far() -> void:
	_add_ball(Vector2(300, 360))  # Far from basket
	_add_basket(Vector2(1130, 360))
	_camera.zoom = Vector2(1.0, 1.0)
	for i in range(60):
		_camera._update_zoom(0.016)
	assert_almost_eq(_camera.zoom.x, 1.0, 0.01, "Zoom should stay at base when far")

func test_zoom_transitions_smoothly() -> void:
	_add_ball(Vector2(1080, 360))
	_add_basket(Vector2(1130, 360))
	_camera.zoom = Vector2(1.0, 1.0)
	_camera._update_zoom(0.016)
	# After one frame, zoom should have moved but not reached target
	assert_gt(_camera.zoom.x, 1.0, "Zoom should start increasing")
	assert_lt(_camera.zoom.x, GameConfig.data.camera_zoom_action,
		"Zoom should not jump to action zoom in one frame")

func test_zoom_x_equals_y() -> void:
	_add_ball(Vector2(1080, 360))
	_add_basket(Vector2(1130, 360))
	_camera.zoom = Vector2(1.0, 1.0)
	_camera._update_zoom(0.016)
	assert_eq(_camera.zoom.x, _camera.zoom.y, "Zoom X and Y should always match")

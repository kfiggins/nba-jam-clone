extends GutTest

var _config: Node
var _manager: Node


func before_each() -> void:
	_config = load("res://scripts/autoload/game_config.gd").new()
	_config.name = "GameConfig"
	add_child(_config)
	_manager = load("res://scripts/autoload/game_manager.gd").new()
	_manager.name = "GameManager"
	add_child(_manager)


func after_each() -> void:
	_manager.queue_free()
	_config.queue_free()


# =============================================================================
# Config default value tests — shot mechanics
# =============================================================================

func test_config_shot_arc_curve_factor() -> void:
	assert_eq(GameConfig.data.shot_arc_curve_factor, 4.0)

func test_config_shot_resolution_distance() -> void:
	assert_eq(GameConfig.data.shot_resolution_distance, 15.0)

func test_config_shot_made_drop_velocity() -> void:
	assert_eq(GameConfig.data.shot_made_drop_velocity, Vector2(0.0, 30.0))

func test_config_shot_made_height() -> void:
	assert_eq(GameConfig.data.shot_made_height, 10.0)

func test_config_shot_made_height_velocity() -> void:
	assert_eq(GameConfig.data.shot_made_height_velocity, -50.0)

func test_config_shot_miss_rim_height_factor() -> void:
	assert_eq(GameConfig.data.shot_miss_rim_height_factor, 0.8)


# =============================================================================
# Config default value tests — pass mechanics
# =============================================================================

func test_config_pass_initial_height() -> void:
	assert_eq(GameConfig.data.pass_initial_height, 20.0)

func test_config_pass_arc_curve_factor() -> void:
	assert_eq(GameConfig.data.pass_arc_curve_factor, 4.0)


# =============================================================================
# Config default value tests — ball held/loose
# =============================================================================

func test_config_ball_hold_offset() -> void:
	assert_eq(GameConfig.data.ball_hold_offset, Vector2(15.0, -5.0))

func test_config_ball_hold_height_offset() -> void:
	assert_eq(GameConfig.data.ball_hold_height_offset, 20.0)

func test_config_ball_ground_friction() -> void:
	assert_eq(GameConfig.data.ball_ground_friction, 200.0)

func test_config_ball_pickup_height_threshold() -> void:
	assert_eq(GameConfig.data.ball_pickup_height_threshold, 30.0)


# =============================================================================
# Config default value tests — player movement
# =============================================================================

func test_config_player_idle_velocity_threshold() -> void:
	assert_eq(GameConfig.data.player_idle_velocity_threshold, 10.0)

func test_config_player_hang_time_threshold() -> void:
	assert_eq(GameConfig.data.player_hang_time_threshold, 0.15)

func test_config_player_hang_time_gravity_factor() -> void:
	assert_eq(GameConfig.data.player_hang_time_gravity_factor, 0.4)

func test_config_dunk_trigger_distance() -> void:
	assert_eq(GameConfig.data.dunk_trigger_distance, 25.0)


# =============================================================================
# Config default value tests — AI
# =============================================================================

func test_config_ai_reaction_speed_variance() -> void:
	assert_eq(GameConfig.data.ai_reaction_speed_variance, 0.05)

func test_config_ai_movement_stop_distance() -> void:
	assert_eq(GameConfig.data.ai_movement_stop_distance, 20.0)

func test_config_ai_guard_distance() -> void:
	assert_eq(GameConfig.data.ai_guard_distance, 30.0)


# =============================================================================
# Config default value tests — camera
# =============================================================================

func test_config_camera_focus_weight() -> void:
	assert_eq(GameConfig.data.camera_focus_weight, 0.7)

func test_config_camera_basket_weight() -> void:
	assert_eq(GameConfig.data.camera_basket_weight, 0.3)

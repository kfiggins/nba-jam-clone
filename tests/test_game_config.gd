extends GutTest


func test_game_config_data_has_default_values() -> void:
	var config := GameConfigData.new()
	assert_eq(config.match_duration, 120.0, "Default match duration should be 120s")
	assert_eq(config.countdown_duration, 3.0, "Default countdown should be 3s")
	assert_eq(config.points_per_shot, 2, "Default points per shot should be 2")
	assert_eq(config.points_per_three, 3, "Default 3-pointer should be 3 points")
	assert_eq(config.enable_three_point_zone, false, "3-point zone off by default")


func test_game_config_data_player_defaults() -> void:
	var config := GameConfigData.new()
	assert_eq(config.player_speed, 300.0)
	assert_eq(config.player_sprint_speed, 450.0)
	assert_eq(config.player_jump_force, 500.0)
	assert_eq(config.player_gravity, 980.0)
	assert_eq(config.player_air_control, 0.3)


func test_game_config_data_ball_defaults() -> void:
	var config := GameConfigData.new()
	assert_eq(config.ball_gravity, 800.0)
	assert_eq(config.ball_bounce_factor, 0.6)
	assert_eq(config.ball_pickup_radius, 30.0)


func test_game_config_data_fire_defaults() -> void:
	var config := GameConfigData.new()
	assert_eq(config.fire_streak_threshold, 3)
	assert_eq(config.fire_shot_bonus, 0.3)


func test_game_config_data_is_resource() -> void:
	var config := GameConfigData.new()
	assert_is(config, Resource, "GameConfigData should extend Resource")


func test_game_config_data_values_are_modifiable() -> void:
	var config := GameConfigData.new()
	config.match_duration = 60.0
	config.player_speed = 500.0
	assert_eq(config.match_duration, 60.0, "Should accept modified match duration")
	assert_eq(config.player_speed, 500.0, "Should accept modified player speed")

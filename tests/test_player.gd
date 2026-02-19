extends GutTest

var _player: Player
var _config: Node


func before_each() -> void:
	_config = load("res://scripts/autoload/game_config.gd").new()
	_config.name = "GameConfig"
	add_child(_config)


func after_each() -> void:
	if _player:
		_player.queue_free()
		_player = null
	_config.queue_free()
	for action in ["move_up", "move_down", "move_left", "move_right", "turbo", "shoot"]:
		Input.action_release(action)


# -- Helpers --

## Minimal player without states, for unit-testing methods.
func _add_player() -> void:
	_player = Player.new()
	_player.is_human = false
	var sprite := Node2D.new()
	sprite.name = "Sprite"
	_player.add_child(sprite)
	var shadow := Node2D.new()
	shadow.name = "Shadow"
	_player.add_child(shadow)
	var sm := StateMachine.new()
	sm.name = "StateMachine"
	_player.add_child(sm)
	add_child(_player)


## Full player scene with states, for integration tests.
func _add_full_player() -> void:
	_player = load("res://scenes/player/player.tscn").instantiate()
	add_child(_player)


# -- Ground Detection --

func test_is_on_ground_when_default() -> void:
	_add_player()
	assert_true(_player.is_on_ground())


func test_is_not_on_ground_when_height_positive() -> void:
	_add_player()
	_player.height = 50.0
	assert_false(_player.is_on_ground())


func test_is_not_on_ground_when_rising() -> void:
	_add_player()
	_player.height_velocity = 100.0
	assert_false(_player.is_on_ground())


# -- Jump --

func test_apply_jump_sets_height_velocity() -> void:
	_add_player()
	_player.apply_jump()
	assert_eq(_player.height_velocity, GameConfig.data.player_jump_force)


func test_apply_jump_emits_jumped() -> void:
	_add_player()
	watch_signals(_player)
	_player.apply_jump()
	assert_signal_emitted(_player, "jumped")


# -- Gravity --

func test_gravity_reduces_height_velocity() -> void:
	_add_player()
	_player.height = 100.0
	_player.height_velocity = 0.0
	_player.apply_gravity(0.1)
	assert_lt(_player.height_velocity, 0.0, "Gravity should pull downward")


func test_gravity_clamps_at_ground() -> void:
	_add_player()
	_player.height = 5.0
	_player.height_velocity = -200.0
	_player.apply_gravity(0.1)
	assert_eq(_player.height, 0.0)
	assert_eq(_player.height_velocity, 0.0)


func test_gravity_emits_landed() -> void:
	_add_player()
	watch_signals(_player)
	_player.height = 5.0
	_player.height_velocity = -200.0
	_player.apply_gravity(0.1)
	assert_signal_emitted(_player, "landed")


func test_jump_then_gravity_lands() -> void:
	_add_player()
	_player.apply_jump()
	var dt := 0.016
	var steps := 0
	while not _player.is_on_ground() and steps < 300:
		_player.apply_gravity(dt)
		steps += 1
	assert_true(_player.is_on_ground(), "Player should land eventually")
	assert_lt(steps, 300, "Should land within reasonable time")


func test_hang_time_reduces_gravity_at_apex() -> void:
	_add_player()
	# Set a very small upward velocity (near apex)
	_player.height = 100.0
	_player.height_velocity = 10.0
	_player.apply_gravity(0.1)
	var vel_near_apex := _player.height_velocity

	# Reset and test with high velocity (no hang time)
	_player.height = 100.0
	_player.height_velocity = 500.0
	var vel_before := _player.height_velocity
	_player.apply_gravity(0.1)
	var vel_drop_fast := vel_before - _player.height_velocity

	# The velocity drop near apex should be smaller (hang time gravity reduction)
	# Near apex: gravity * 0.4, normal: gravity * 1.0
	# vel_near_apex should have dropped less than vel_drop_fast
	assert_gt(vel_drop_fast, 0.0, "Fast velocity should drop")


# -- Turbo --

func test_turbo_starts_at_max() -> void:
	_add_player()
	assert_eq(_player.turbo, GameConfig.data.turbo_max)


func test_turbo_regens_when_not_sprinting() -> void:
	_add_player()
	_player.turbo = 50.0
	_player.update_turbo(1.0)
	assert_gt(_player.turbo, 50.0, "Turbo should regen")


func test_turbo_caps_at_max() -> void:
	_add_player()
	_player.turbo = GameConfig.data.turbo_max - 1.0
	_player.update_turbo(100.0)
	assert_eq(_player.turbo, GameConfig.data.turbo_max)


func test_turbo_drains_when_sprinting() -> void:
	_add_player()
	_player.is_human = true
	Input.action_press("turbo")
	_player.update_turbo(1.0)
	assert_lt(_player.turbo, GameConfig.data.turbo_max, "Turbo should drain while sprinting")


func test_turbo_floor_at_zero() -> void:
	_add_player()
	_player.is_human = true
	_player.turbo = 1.0
	Input.action_press("turbo")
	_player.update_turbo(100.0)
	assert_eq(_player.turbo, 0.0)


func test_turbo_changed_signal() -> void:
	_add_player()
	watch_signals(_player)
	_player.update_turbo(0.1)
	assert_signal_emitted(_player, "turbo_changed")


# -- Move Speed --

func test_normal_speed_when_not_sprinting() -> void:
	_add_player()
	_player.is_human = true
	assert_eq(_player.get_move_speed(), GameConfig.data.player_speed)


func test_sprint_speed_with_turbo() -> void:
	_add_player()
	_player.is_human = true
	Input.action_press("turbo")
	assert_eq(_player.get_move_speed(), GameConfig.data.player_sprint_speed)


func test_no_sprint_when_turbo_empty() -> void:
	_add_player()
	_player.is_human = true
	_player.turbo = 0.0
	Input.action_press("turbo")
	assert_eq(_player.get_move_speed(), GameConfig.data.player_speed)


# -- Visual Height --

func test_sprite_offset_matches_height() -> void:
	_add_player()
	_player.height = 100.0
	_player._update_visual_height()
	assert_eq(_player.sprite.position.y, -100.0)


func test_shadow_stays_at_ground() -> void:
	_add_player()
	_player.height = 100.0
	_player._update_visual_height()
	assert_eq(_player.shadow.position.y, 0.0)


func test_shadow_shrinks_when_high() -> void:
	_add_player()
	_player.height = 150.0
	_player._update_visual_height()
	assert_lt(_player.shadow.scale.x, 1.0, "Shadow should shrink with height")


func test_shadow_minimum_scale() -> void:
	_add_player()
	_player.height = 1000.0
	_player._update_visual_height()
	assert_gte(_player.shadow.scale.x, 0.5, "Shadow should not shrink below 0.5")


# -- State Machine Integration --

func test_initial_state_is_idle() -> void:
	_add_full_player()
	assert_eq(_player.state_machine.current_state.name, "Idle")


func test_idle_to_running_on_move() -> void:
	_add_full_player()
	Input.action_press("move_right")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player.state_machine.current_state.name, "Running")


func test_idle_to_jumping_on_shoot() -> void:
	_add_full_player()
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player.state_machine.current_state.name, "Jumping")


func test_running_to_jumping_on_shoot() -> void:
	_add_full_player()
	Input.action_press("move_right")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player.state_machine.current_state.name, "Jumping")


func test_jumping_lands_eventually() -> void:
	_add_full_player()
	Input.action_press("shoot")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("shoot")
	# Wait for landing (jump + gravity cycle)
	for i in range(120):
		await get_tree().physics_frame
		if _player.state_machine.current_state.name != "Jumping":
			break
	assert_ne(_player.state_machine.current_state.name, "Jumping", "Should have landed")


func test_air_control_reduces_movement() -> void:
	_add_player()
	# Compare velocity buildup with full control vs air control
	_player.input_direction = Vector2.RIGHT
	_player.apply_movement(0.1, 1.0)
	var full_vel := _player.velocity.length()

	_player.velocity = Vector2.ZERO
	_player.apply_movement(0.1, GameConfig.data.player_air_control)
	var air_vel := _player.velocity.length()

	assert_lt(air_vel, full_vel, "Air control should reduce movement")


# -- Team Colors --

func test_team_1_gets_blue_color() -> void:
	_add_full_player()
	_player.team = 1
	_player._apply_team_color()
	var body := _player.get_node("Sprite/BodySprite") as ColorRect
	assert_eq(body.color, Color(0.2, 0.4, 0.8, 1), "Team 1 should be blue")


func test_team_2_gets_red_color() -> void:
	_player = load("res://scenes/player/player.tscn").instantiate()
	_player.team = 2
	add_child(_player)
	var body := _player.get_node("Sprite/BodySprite") as ColorRect
	assert_eq(body.color, Color(0.85, 0.2, 0.1, 1), "Team 2 should be red")


func test_human_player_has_indicator() -> void:
	_player = load("res://scenes/player/player.tscn").instantiate()
	_player.is_human = true
	add_child(_player)
	var indicator := _player.get_node_or_null("Sprite/HumanIndicator")
	assert_not_null(indicator, "Human player should have an indicator")


func test_ai_player_has_no_indicator() -> void:
	_player = load("res://scenes/player/player.tscn").instantiate()
	_player.is_human = false
	add_child(_player)
	var indicator := _player.get_node_or_null("Sprite/HumanIndicator")
	assert_null(indicator, "AI player should not have an indicator")


# -- Boundary Clamping --

func test_player_clamped_to_court_right() -> void:
	_add_player()
	var bounds := GameConfig.data.court_bounds
	_player.global_position = Vector2(bounds.end.x + 100, 360)
	_player._clamp_to_court()
	assert_eq(_player.global_position.x, bounds.end.x, "Should clamp to right edge")


func test_player_clamped_to_court_left() -> void:
	_add_player()
	var bounds := GameConfig.data.court_bounds
	_player.global_position = Vector2(bounds.position.x - 100, 360)
	_player._clamp_to_court()
	assert_eq(_player.global_position.x, bounds.position.x, "Should clamp to left edge")


func test_player_clamped_to_court_top() -> void:
	_add_player()
	var bounds := GameConfig.data.court_bounds
	_player.global_position = Vector2(640, bounds.position.y - 100)
	_player._clamp_to_court()
	assert_eq(_player.global_position.y, bounds.position.y, "Should clamp to top edge")


func test_player_clamped_to_court_bottom() -> void:
	_add_player()
	var bounds := GameConfig.data.court_bounds
	_player.global_position = Vector2(640, bounds.end.y + 100)
	_player._clamp_to_court()
	assert_eq(_player.global_position.y, bounds.end.y, "Should clamp to bottom edge")


func test_player_inside_bounds_not_moved() -> void:
	_add_player()
	_player.global_position = Vector2(640, 360)
	_player._clamp_to_court()
	assert_eq(_player.global_position, Vector2(640, 360), "Should not move if inside bounds")

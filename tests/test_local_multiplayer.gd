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


func _make_player(idx: int = 0) -> Player:
	var p := Player.new()
	p.is_human = true
	p.player_index = idx
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
	return p


# =============================================================================
# get_action_name
# =============================================================================

func test_player_index_0_uses_original_action_names() -> void:
	var p := _make_player(0)
	assert_eq(p.get_action_name("shoot"), "shoot")
	assert_eq(p.get_action_name("move_left"), "move_left")
	assert_eq(p.get_action_name("move_right"), "move_right")
	assert_eq(p.get_action_name("move_up"), "move_up")
	assert_eq(p.get_action_name("move_down"), "move_down")
	assert_eq(p.get_action_name("pass_ball"), "pass_ball")
	assert_eq(p.get_action_name("turbo"), "turbo")
	p.queue_free()


func test_player_index_1_uses_p2_prefix() -> void:
	var p := _make_player(1)
	assert_eq(p.get_action_name("shoot"), "p2_shoot")
	assert_eq(p.get_action_name("move_left"), "p2_move_left")
	assert_eq(p.get_action_name("move_right"), "p2_move_right")
	assert_eq(p.get_action_name("move_up"), "p2_move_up")
	assert_eq(p.get_action_name("move_down"), "p2_move_down")
	assert_eq(p.get_action_name("pass_ball"), "p2_pass_ball")
	assert_eq(p.get_action_name("turbo"), "p2_turbo")
	p.queue_free()


func test_player_index_2_uses_p3_prefix() -> void:
	var p := _make_player(2)
	assert_eq(p.get_action_name("shoot"), "p3_shoot")
	assert_eq(p.get_action_name("pass_ball"), "p3_pass_ball")
	p.queue_free()


# =============================================================================
# wants_action for AI players (testable without frame issues)
# =============================================================================

func test_wants_action_ai_returns_flag_true() -> void:
	var p := _make_player(0)
	p.is_human = false
	assert_true(p.wants_action("shoot", true))
	p.queue_free()


func test_wants_action_ai_returns_flag_false() -> void:
	var p := _make_player(0)
	p.is_human = false
	assert_false(p.wants_action("shoot", false))
	p.queue_free()


func test_wants_action_ai_ignores_player_index() -> void:
	var p := _make_player(1)
	p.is_human = false
	assert_true(p.wants_action("shoot", true))
	assert_false(p.wants_action("shoot", false))
	p.queue_free()


# =============================================================================
# PlayerSetupData resource
# =============================================================================

func test_player_setup_data_defaults() -> void:
	var data := PlayerSetupData.new()
	assert_eq(data.team, 1)
	assert_eq(data.is_human, false)
	assert_eq(data.player_index, 0)
	assert_eq(data.archetype, null)
	assert_eq(data.spawn_position, Vector2.ZERO)


func test_player_setup_data_configurable() -> void:
	var data := PlayerSetupData.new()
	data.team = 2
	data.is_human = true
	data.player_index = 1
	data.spawn_position = Vector2(500, 300)
	assert_eq(data.team, 2)
	assert_eq(data.is_human, true)
	assert_eq(data.player_index, 1)
	assert_eq(data.spawn_position, Vector2(500, 300))


func test_player_setup_data_with_archetype() -> void:
	var data := PlayerSetupData.new()
	var arch := PlayerArchetype.new()
	arch.archetype_name = "Speed"
	data.archetype = arch
	assert_eq(data.archetype.archetype_name, "Speed")


# =============================================================================
# Player index default
# =============================================================================

func test_player_index_defaults_to_zero() -> void:
	var p := Player.new()
	assert_eq(p.player_index, 0)
	p.queue_free()


# =============================================================================
# P2 input actions exist in project
# =============================================================================

func test_p2_actions_registered() -> void:
	assert_true(InputMap.has_action("p2_move_left"), "p2_move_left should exist")
	assert_true(InputMap.has_action("p2_move_right"), "p2_move_right should exist")
	assert_true(InputMap.has_action("p2_move_up"), "p2_move_up should exist")
	assert_true(InputMap.has_action("p2_move_down"), "p2_move_down should exist")
	assert_true(InputMap.has_action("p2_shoot"), "p2_shoot should exist")
	assert_true(InputMap.has_action("p2_pass_ball"), "p2_pass_ball should exist")
	assert_true(InputMap.has_action("p2_turbo"), "p2_turbo should exist")


func test_original_actions_still_exist() -> void:
	assert_true(InputMap.has_action("move_left"), "Original move_left should still exist")
	assert_true(InputMap.has_action("shoot"), "Original shoot should still exist")
	assert_true(InputMap.has_action("turbo"), "Original turbo should still exist")
	assert_true(InputMap.has_action("restart"), "Restart should still exist")

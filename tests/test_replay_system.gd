extends GutTest

var _replay: ReplaySystem
var _config: Node
var _manager: Node
var _saved_time_scale: float


func before_each() -> void:
	_saved_time_scale = Engine.time_scale
	_config = load("res://scripts/autoload/game_config.gd").new()
	_config.name = "GameConfig"
	add_child(_config)
	_manager = load("res://scripts/autoload/game_manager.gd").new()
	_manager.name = "GameManager"
	add_child(_manager)
	_replay = ReplaySystem.new()
	_replay.name = "ReplaySystem"
	add_child(_replay)


func after_each() -> void:
	Engine.time_scale = _saved_time_scale
	_replay.queue_free()
	_manager.queue_free()
	_config.queue_free()


func _make_player() -> Player:
	var p := Player.new()
	p.is_human = false
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
# Config defaults
# =============================================================================

func test_config_replay_duration() -> void:
	assert_eq(GameConfig.data.replay_duration, 1.5)

func test_config_replay_slow_mo_scale() -> void:
	assert_eq(GameConfig.data.replay_slow_mo_scale, 0.3)

func test_config_camera_replay_zoom() -> void:
	assert_eq(GameConfig.data.camera_replay_zoom, 1.3)

func test_config_enable_dunk_replay() -> void:
	assert_eq(GameConfig.data.enable_dunk_replay, true)


# =============================================================================
# ReplaySystem state
# =============================================================================

func test_not_replaying_initially() -> void:
	assert_false(_replay.is_replaying())

func test_start_replay_sets_replaying() -> void:
	var p := _make_player()
	_replay.start_replay(p, 1.0, 0.3)
	assert_true(_replay.is_replaying())
	Engine.time_scale = _saved_time_scale
	p.queue_free()

func test_start_replay_changes_time_scale() -> void:
	var p := _make_player()
	_replay.start_replay(p, 1.0, 0.3)
	assert_eq(Engine.time_scale, 0.3)
	Engine.time_scale = _saved_time_scale
	p.queue_free()

func test_start_replay_sets_target() -> void:
	var p := _make_player()
	_replay.start_replay(p, 1.0, 0.3)
	assert_eq(_replay.get_replay_target(), p)
	Engine.time_scale = _saved_time_scale
	p.queue_free()

func test_double_start_is_noop() -> void:
	var p := _make_player()
	_replay.start_replay(p, 1.0, 0.3)
	_replay.start_replay(p, 1.0, 0.5)
	assert_eq(Engine.time_scale, 0.3, "Second start_replay should be ignored")
	Engine.time_scale = _saved_time_scale
	p.queue_free()


# =============================================================================
# Signals
# =============================================================================

func test_replay_started_signal() -> void:
	var p := _make_player()
	watch_signals(_replay)
	_replay.start_replay(p, 1.0, 0.3)
	assert_signal_emitted(_replay, "replay_started")
	Engine.time_scale = _saved_time_scale
	p.queue_free()

func test_replay_target_null_initially() -> void:
	assert_eq(_replay.get_replay_target(), null)


# =============================================================================
# Camera replay target
# =============================================================================

func test_camera_replay_target_overrides_tracking() -> void:
	var camera := GameCamera.new()
	add_child(camera)
	var p := _make_player()
	p.global_position = Vector2(500, 300)
	camera.set_replay_target(p)
	# The private method should return the replay target's position
	var target: Vector2 = camera._get_target_position()
	assert_eq(target, Vector2(500, 300))
	camera.clear_replay_target()
	camera.queue_free()
	p.queue_free()

func test_camera_clear_replay_target() -> void:
	var camera := GameCamera.new()
	add_child(camera)
	var p := _make_player()
	camera.set_replay_target(p)
	camera.clear_replay_target()
	assert_eq(camera._replay_target, null)
	camera.queue_free()
	p.queue_free()

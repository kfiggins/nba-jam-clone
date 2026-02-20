extends GutTest

var _config: Node
var _manager: Node
var _audio: Node


func before_each() -> void:
	_config = load("res://scripts/autoload/game_config.gd").new()
	_config.name = "GameConfig"
	add_child(_config)
	_manager = load("res://scripts/autoload/game_manager.gd").new()
	_manager.name = "GameManager"
	add_child(_manager)
	_audio = load("res://scripts/audio/audio_manager.gd").new()
	_audio.name = "AudioManager"
	add_child(_audio)


func after_each() -> void:
	_audio.queue_free()
	_manager.queue_free()
	_config.queue_free()


# =============================================================================
# Config tests
# =============================================================================

func test_config_shake_dunk_intensity() -> void:
	assert_eq(GameConfig.data.shake_dunk_intensity, 8.0)

func test_config_shake_block_intensity() -> void:
	assert_eq(GameConfig.data.shake_block_intensity, 6.0)

func test_config_ball_trail_length() -> void:
	assert_eq(GameConfig.data.ball_trail_length, 8)

func test_config_rim_shake_intensity() -> void:
	assert_eq(GameConfig.data.rim_shake_intensity, 4.0)

func test_config_score_flash_scale() -> void:
	assert_eq(GameConfig.data.score_flash_scale, 1.5)


# =============================================================================
# Screen shake tests
# =============================================================================

func test_shake_sets_intensity() -> void:
	var camera := GameCamera.new()
	add_child(camera)
	camera.shake(8.0, 0.3)
	assert_eq(camera._shake_intensity, 8.0)
	assert_eq(camera._shake_remaining, 0.3)
	camera.queue_free()

func test_shake_decays_over_time() -> void:
	var camera := GameCamera.new()
	add_child(camera)
	camera.shake(8.0, 0.3)
	camera._update_shake(0.1)
	assert_lt(camera._shake_remaining, 0.3,
		"Shake remaining should decrease after processing")
	camera.queue_free()

func test_shake_offset_applied_during_shake() -> void:
	var camera := GameCamera.new()
	add_child(camera)
	camera.shake(100.0, 1.0)
	camera._update_shake(0.01)
	assert_gt(camera._shake_remaining, 0.0, "Shake should still be active")
	camera.queue_free()

func test_shake_clears_after_duration() -> void:
	var camera := GameCamera.new()
	add_child(camera)
	camera.shake(8.0, 0.3)
	camera._update_shake(0.5)
	assert_eq(camera._shake_intensity, 0.0, "Intensity should be zero after shake ends")
	assert_eq(camera._shake_remaining, 0.0, "Remaining should be zero after shake ends")
	assert_eq(camera.offset, Vector2.ZERO, "Offset should reset to zero")
	camera.queue_free()


# =============================================================================
# Ball trail tests
# =============================================================================

func test_trail_adds_points_when_fast() -> void:
	var ball: Ball = load("res://scenes/ball/ball.tscn").instantiate() as Ball
	add_child(ball)
	ball.ground_velocity = Vector2(500, 0)
	ball._update_trail()
	assert_gt(ball.trail.get_point_count(), 0, "Trail should have points at high speed")
	ball.queue_free()

func test_trail_clears_when_slow() -> void:
	var ball: Ball = load("res://scenes/ball/ball.tscn").instantiate() as Ball
	add_child(ball)
	ball.ground_velocity = Vector2(500, 0)
	ball._update_trail()
	assert_gt(ball.trail.get_point_count(), 0)
	ball.ground_velocity = Vector2(10, 0)
	ball._update_trail()
	assert_eq(ball.trail.get_point_count(), 0, "Trail should clear at low speed")
	ball.queue_free()

func test_trail_max_length() -> void:
	var ball: Ball = load("res://scenes/ball/ball.tscn").instantiate() as Ball
	add_child(ball)
	ball.ground_velocity = Vector2(500, 0)
	for i in range(20):
		ball.global_position.x += 10.0
		ball._update_trail()
	assert_true(ball.trail.get_point_count() <= GameConfig.data.ball_trail_length,
		"Trail should not exceed max length")
	ball.queue_free()


# =============================================================================
# Rim shake tests
# =============================================================================

func test_rim_shake_creates_tween() -> void:
	var basket: Basket = load("res://scenes/court/basket.tscn").instantiate() as Basket
	add_child(basket)
	var tween: Tween = basket.rim_shake()
	assert_not_null(tween, "rim_shake should return a Tween")
	basket.queue_free()

func test_rim_node_exists_in_basket() -> void:
	var basket: Basket = load("res://scenes/court/basket.tscn").instantiate() as Basket
	add_child(basket)
	var rim: Node2D = basket.get_node("Rim") as Node2D
	assert_not_null(rim, "Basket should have a Rim child")
	basket.queue_free()


# =============================================================================
# Score flash tests
# =============================================================================

func test_score_flash_returns_tween() -> void:
	var hud: CanvasLayer = load("res://scenes/ui/hud.tscn").instantiate() as CanvasLayer
	add_child(hud)
	var label: Label = hud.get_node("%Team1Score") as Label
	var tween: Tween = hud._flash_label(label)
	assert_not_null(tween, "_flash_label should return a Tween")
	hud.queue_free()

func test_score_flash_triggers_on_score_change() -> void:
	var hud: CanvasLayer = load("res://scenes/ui/hud.tscn").instantiate() as CanvasLayer
	add_child(hud)
	var label: Label = hud.get_node("%Team1Score") as Label
	hud._on_score_changed(1, 5)
	assert_eq(label.text, "5", "Score should update")
	assert_ne(label.pivot_offset, Vector2.ZERO,
		"pivot_offset should be set after flash")
	hud.queue_free()


# =============================================================================
# Audio manager tests
# =============================================================================

func test_audio_manager_emits_sfx_signal() -> void:
	watch_signals(_audio)
	_audio.play_sfx("swish")
	assert_signal_emitted_with_parameters(_audio, "sfx_requested", ["swish"])

func test_audio_dunk_sfx() -> void:
	watch_signals(_audio)
	_audio.play_sfx("dunk")
	assert_signal_emitted_with_parameters(_audio, "sfx_requested", ["dunk"])

func test_audio_block_sfx() -> void:
	watch_signals(_audio)
	_audio.play_sfx("block")
	assert_signal_emitted_with_parameters(_audio, "sfx_requested", ["block"])

func test_audio_steal_sfx() -> void:
	watch_signals(_audio)
	_audio.play_sfx("steal")
	assert_signal_emitted_with_parameters(_audio, "sfx_requested", ["steal"])

func test_audio_buzzer_sfx() -> void:
	watch_signals(_audio)
	_audio.play_sfx("buzzer")
	assert_signal_emitted_with_parameters(_audio, "sfx_requested", ["buzzer"])

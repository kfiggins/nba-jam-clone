class_name GameCamera
extends Camera2D
## Tracks the action: follows the ball + nearby players, biases toward the basket,
## zooms in when the ball is near the rim, and provides screen shake.

const COURT_WIDTH := 1280.0
const COURT_HEIGHT := 720.0

var _shake_intensity: float = 0.0
var _shake_remaining: float = 0.0
var _shake_duration: float = 0.0


func _ready() -> void:
	enabled = true
	limit_left = 0
	limit_right = int(COURT_WIDTH)
	limit_top = 0
	limit_bottom = int(COURT_HEIGHT)


func shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_remaining = duration


func _physics_process(delta: float) -> void:
	var target := _get_target_position()
	global_position = global_position.lerp(target, GameConfig.data.camera_smooth_speed * delta)
	_update_zoom(delta)
	_update_shake(delta)


func _update_shake(delta: float) -> void:
	if _shake_remaining > 0.0:
		_shake_remaining -= delta
		var decay := _shake_remaining / _shake_duration if _shake_duration > 0.0 else 0.0
		var shake_amount := _shake_intensity * decay
		offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		if _shake_remaining <= 0.0:
			_shake_remaining = 0.0
			_shake_intensity = 0.0
			offset = Vector2.ZERO
	else:
		offset = Vector2.ZERO


func _get_target_position() -> Vector2:
	var ball := _get_ball()
	if not ball:
		return Vector2(COURT_WIDTH * 0.5, COURT_HEIGHT * 0.5)

	var ball_pos := ball.global_position
	var players := _get_nearest_players(ball_pos, 2)

	# Average ball + nearest players for focus point
	var focus := ball_pos
	if players.size() > 0:
		var player_avg := Vector2.ZERO
		for p in players:
			player_avg += p.global_position
		player_avg /= players.size()
		focus = (ball_pos + player_avg) * 0.5

	# Blend in basket position to keep it visible
	var basket_pos := _get_basket_position()
	var config := GameConfig.data
	var target := focus * config.camera_focus_weight + basket_pos * config.camera_basket_weight

	# Bias toward basket side
	target.x += config.camera_offset_x

	return target


func _update_zoom(delta: float) -> void:
	var config := GameConfig.data
	var ball := _get_ball()
	var target_zoom := config.camera_zoom_base

	if ball:
		var basket_pos := _get_basket_position()
		var dist := ball.global_position.distance_to(basket_pos)
		if dist < config.camera_action_range:
			target_zoom = config.camera_zoom_action

	var current := zoom.x
	var new_zoom := lerpf(current, target_zoom, config.camera_zoom_smooth_speed * delta)
	zoom = Vector2(new_zoom, new_zoom)


func _get_ball() -> Node2D:
	var nodes := get_tree().get_nodes_in_group("ball")
	if nodes.size() > 0:
		return nodes[0] as Node2D
	return null


func _get_basket_position() -> Vector2:
	var nodes := get_tree().get_nodes_in_group("basket")
	if nodes.size() > 0:
		return (nodes[0] as Node2D).global_position
	return Vector2(1130.0, 360.0)


func _get_nearest_players(pos: Vector2, count: int) -> Array:
	var players := get_tree().get_nodes_in_group("players")
	players.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(pos) < b.global_position.distance_squared_to(pos)
	)
	return players.slice(0, count)



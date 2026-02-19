class_name ReplaySystem
extends Node
## Brief slow-motion celebration after dunks.
## Slows Engine.time_scale, tracks real-time duration, then restores.

signal replay_started
signal replay_ended

var _is_replaying: bool = false
var _replay_timer: float = 0.0
var _replay_duration: float = 0.0
var _original_time_scale: float = 1.0
var _target_player: Player = null


func is_replaying() -> bool:
	return _is_replaying


func get_replay_target() -> Player:
	return _target_player


func start_replay(player: Player, duration: float, slow_mo_scale: float) -> void:
	if _is_replaying:
		return
	_is_replaying = true
	_target_player = player
	_replay_duration = duration
	_replay_timer = 0.0
	_original_time_scale = Engine.time_scale
	Engine.time_scale = slow_mo_scale
	replay_started.emit()


func _process(delta: float) -> void:
	if not _is_replaying:
		return
	# Track real time: delta is already scaled by Engine.time_scale,
	# so divide by current time_scale to get real elapsed time
	if Engine.time_scale > 0.0:
		_replay_timer += delta / Engine.time_scale
	else:
		_replay_timer += delta
	if _replay_timer >= _replay_duration:
		_end_replay()


func _end_replay() -> void:
	_is_replaying = false
	Engine.time_scale = _original_time_scale
	_target_player = null
	replay_ended.emit()

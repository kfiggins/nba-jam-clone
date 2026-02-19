extends Node2D
## Main scene. Wires up HUD, handles match start/restart, attaches AI controllers,
## manages possession resets, streak tracking, HUD feedback, and juice effects.

var _replay_system: ReplaySystem
var _player_scene: PackedScene = preload("res://scenes/player/player.tscn")

## Default configs: 1 human P1 team 1, 3 AI
const DEFAULT_SPAWN_POSITIONS := [
	Vector2(400, 400), Vector2(350, 300),
	Vector2(800, 400), Vector2(750, 300),
]


func _ready() -> void:
	_replay_system = ReplaySystem.new()
	_replay_system.name = "ReplaySystem"
	_replay_system.replay_ended.connect(_on_replay_ended)
	add_child(_replay_system)
	_setup_players()
	GameManager.possession_reset.connect(_on_possession_reset)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	var ball := _get_ball()
	if ball:
		ball.shot_made.connect(_on_shot_made)
		ball.dunk_made.connect(_on_dunk_made)
		ball.shot_missed.connect(_on_shot_missed)
		ball.shot_blocked.connect(_on_shot_blocked)
		ball.ball_stolen.connect(_on_ball_stolen)
		ball.owner_changed.connect(_on_owner_changed)


func _setup_players() -> void:
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p and not p.is_human:
			var controller := AIController.new()
			controller.name = "AIController"
			p.add_child(controller)
		if p:
			p.caught_fire.connect(_on_player_caught_fire.bind(p))
			p.fire_ended.connect(_on_player_fire_ended.bind(p))


func spawn_players(configs: Array) -> void:
	# Remove existing players
	for node in get_tree().get_nodes_in_group("players"):
		node.queue_free()
	# Wait one frame for queue_free to process
	await get_tree().process_frame
	# Spawn new players
	for i in range(configs.size()):
		var config: PlayerSetupData = configs[i]
		var p: Player = _player_scene.instantiate()
		p.team = config.team
		p.is_human = config.is_human
		p.player_index = config.player_index
		if config.archetype:
			p.archetype = config.archetype
		p.position = config.spawn_position if config.spawn_position != Vector2.ZERO else DEFAULT_SPAWN_POSITIONS[i % DEFAULT_SPAWN_POSITIONS.size()]
		add_child(p)
	_setup_players()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		match GameManager.state:
			GameManager.MatchState.PREGAME:
				GameManager.start_match()
			GameManager.MatchState.RESULTS:
				GameManager.restart()


func _on_possession_reset(receiving_team: int) -> void:
	var ball := _get_ball()
	var receiver := _get_inbound_player(receiving_team)
	if ball and receiver:
		ball.reset_to(GameConfig.data.inbound_position, receiver)


func _on_shot_made(shooter: Player, points: int) -> void:
	if shooter:
		shooter.add_streak()
	var hud := _get_hud()
	if hud:
		hud.on_shot_made(points)
	AudioManager.play_sfx("swish")


func _on_dunk_made(dunker: Player, _points: int) -> void:
	if dunker:
		dunker.add_streak()
	var hud := _get_hud()
	if hud:
		hud.on_dunk_made()
	var config := GameConfig.data
	var camera := _get_camera()
	if camera:
		camera.shake(config.shake_dunk_intensity, config.shake_dunk_duration)
	var basket := _get_basket()
	if basket:
		basket.rim_shake()
	AudioManager.play_sfx("dunk")
	# Dunk replay
	if config.enable_dunk_replay and dunker:
		if camera:
			camera.set_replay_target(dunker)
		_replay_system.start_replay(dunker, config.replay_duration, config.replay_slow_mo_scale)


func _on_replay_ended() -> void:
	var camera := _get_camera()
	if camera:
		camera.clear_replay_target()


func _on_shot_missed(shooter: Player) -> void:
	if shooter:
		shooter.reset_streak()
	var hud := _get_hud()
	if hud:
		hud.on_shot_missed()


func _on_shot_blocked(_blocker: Player, shooter: Player) -> void:
	if shooter:
		shooter.reset_streak()
	var hud := _get_hud()
	if hud:
		hud.on_shot_blocked()
	var config := GameConfig.data
	var camera := _get_camera()
	if camera:
		camera.shake(config.shake_block_intensity, config.shake_block_duration)
	AudioManager.play_sfx("block")


func _on_ball_stolen(_stealer: Player, victim: Player) -> void:
	if victim:
		victim.reset_streak()
	var hud := _get_hud()
	if hud:
		hud.on_ball_stolen()
	AudioManager.play_sfx("steal")


func _on_owner_changed(_old_owner: Player, new_owner: Player) -> void:
	var hud := _get_hud()
	if hud:
		if new_owner:
			hud.update_possession(new_owner.team)
		else:
			hud.update_possession(0)


func _on_player_caught_fire(player: Player) -> void:
	var hud := _get_hud()
	if hud:
		hud.on_player_caught_fire(player)


func _on_player_fire_ended(player: Player) -> void:
	var hud := _get_hud()
	if hud:
		hud.on_player_fire_ended(player)


func _on_game_state_changed(_old_state: GameManager.MatchState, new_state: GameManager.MatchState) -> void:
	if new_state == GameManager.MatchState.BUZZER:
		AudioManager.play_sfx("buzzer")


func _get_ball() -> Ball:
	for node in get_tree().get_nodes_in_group("ball"):
		return node as Ball
	return null


func _get_hud() -> CanvasLayer:
	return $HUD if has_node("HUD") else null


func _get_camera() -> GameCamera:
	for node in get_tree().get_nodes_in_group("camera"):
		return node as GameCamera
	if has_node("GameCamera"):
		return $GameCamera as GameCamera
	return null


func _get_basket() -> Basket:
	for node in get_tree().get_nodes_in_group("basket"):
		return node as Basket
	return null


func _get_inbound_player(team: int) -> Player:
	var best: Player = null
	var best_dist := INF
	var inbound_pos := GameConfig.data.inbound_position
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p and p.team == team:
			var dist := p.global_position.distance_to(inbound_pos)
			if dist < best_dist:
				best_dist = dist
				best = p
	return best

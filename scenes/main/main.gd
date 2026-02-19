extends Node2D
## Main scene. Wires up HUD, handles match start/restart, attaches AI controllers,
## manages possession resets, streak tracking, and HUD feedback.


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p and not p.is_human:
			var controller := AIController.new()
			controller.name = "AIController"
			p.add_child(controller)
		if p:
			p.caught_fire.connect(_on_player_caught_fire.bind(p))
			p.fire_ended.connect(_on_player_fire_ended.bind(p))
	GameManager.possession_reset.connect(_on_possession_reset)
	var ball := _get_ball()
	if ball:
		ball.shot_made.connect(_on_shot_made)
		ball.dunk_made.connect(_on_dunk_made)
		ball.shot_missed.connect(_on_shot_missed)
		ball.shot_blocked.connect(_on_shot_blocked)
		ball.ball_stolen.connect(_on_ball_stolen)
		ball.owner_changed.connect(_on_owner_changed)


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


func _on_dunk_made(dunker: Player, _points: int) -> void:
	if dunker:
		dunker.add_streak()
	var hud := _get_hud()
	if hud:
		hud.on_dunk_made()


func _on_shot_missed(shooter: Player) -> void:
	if shooter:
		shooter.reset_streak()


func _on_shot_blocked(_blocker: Player, shooter: Player) -> void:
	if shooter:
		shooter.reset_streak()
	var hud := _get_hud()
	if hud:
		hud.on_shot_blocked()


func _on_ball_stolen(_stealer: Player, victim: Player) -> void:
	if victim:
		victim.reset_streak()
	var hud := _get_hud()
	if hud:
		hud.on_ball_stolen()


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


func _get_ball() -> Ball:
	for node in get_tree().get_nodes_in_group("ball"):
		return node as Ball
	return null


func _get_hud() -> CanvasLayer:
	return $HUD if has_node("HUD") else null


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

extends Node
## Global game manager singleton.
## Manages match state (PREGAME → COUNTDOWN → PLAYING → BUZZER → RESULTS),
## score tracking, game clock, possession changes, and shot clock.

signal score_changed(team: int, new_score: int)
signal game_state_changed(old_state: MatchState, new_state: MatchState)
signal clock_updated(time_remaining: float)
signal countdown_tick(seconds_left: int)
signal match_ended(winner: int) # 0 = draw, 1 = team1, 2 = team2
signal possession_reset(receiving_team: int)
signal shot_clock_expired(team: int)
signal shot_clock_updated(time_left: float)

enum MatchState {
	PREGAME,
	COUNTDOWN,
	PLAYING,
	BUZZER,
	RESULTS,
}

var state: MatchState = MatchState.PREGAME
var scores: Array[int] = [0, 0] # team 1, team 2
var time_remaining: float = 0.0
var countdown_remaining: float = 0.0
var _last_countdown_second: int = -1
var winner: int = 0 # 0 = draw, 1 or 2 = team

## Possession tracking
var last_scoring_team: int = 0
var score_pause_timer: float = 0.0

## Shot clock
var shot_clock_remaining: float = 0.0
var shot_clock_team: int = 0


func _process(delta: float) -> void:
	match state:
		MatchState.COUNTDOWN:
			_process_countdown(delta)
		MatchState.PLAYING:
			_process_playing(delta)


func start_match() -> void:
	scores = [0, 0]
	winner = 0
	last_scoring_team = 0
	score_pause_timer = 0.0
	shot_clock_remaining = 0.0
	shot_clock_team = 0
	time_remaining = GameConfig.data.match_duration
	_change_state(MatchState.COUNTDOWN)


func add_score(team: int, points: int = 0) -> void:
	if state != MatchState.PLAYING:
		return
	if team < 1 or team > 2:
		push_warning("GameManager: Invalid team index %d" % team)
		return
	if points <= 0:
		points = GameConfig.data.points_per_shot
	scores[team - 1] += points
	last_scoring_team = team
	score_pause_timer = GameConfig.data.score_pause_duration
	shot_clock_remaining = 0.0
	score_changed.emit(team, scores[team - 1])


func get_score(team: int) -> int:
	if team < 1 or team > 2:
		return 0
	return scores[team - 1]


func get_time_remaining() -> float:
	return time_remaining


func get_winner() -> int:
	if scores[0] > scores[1]:
		return 1
	elif scores[1] > scores[0]:
		return 2
	else:
		return 0


## Call when ball ownership changes to update shot clock.
func on_possession_changed(team: int) -> void:
	if not GameConfig.data.enable_shot_clock:
		return
	if team != shot_clock_team and team > 0:
		shot_clock_team = team
		shot_clock_remaining = GameConfig.data.shot_clock_duration


func restart() -> void:
	start_match()


func _process_countdown(delta: float) -> void:
	countdown_remaining -= delta
	var seconds_left := ceili(countdown_remaining)
	if seconds_left != _last_countdown_second and seconds_left > 0:
		_last_countdown_second = seconds_left
		countdown_tick.emit(seconds_left)
	if countdown_remaining <= 0.0:
		countdown_remaining = 0.0
		_change_state(MatchState.PLAYING)


func _process_playing(delta: float) -> void:
	# Score pause timer — possession reset after scoring
	if score_pause_timer > 0.0:
		score_pause_timer -= delta
		if score_pause_timer <= 0.0:
			score_pause_timer = 0.0
			var receiving := 1 if last_scoring_team == 2 else 2
			possession_reset.emit(receiving)

	# Shot clock
	if GameConfig.data.enable_shot_clock and shot_clock_remaining > 0.0:
		shot_clock_remaining -= delta
		shot_clock_updated.emit(shot_clock_remaining)
		if shot_clock_remaining <= 0.0:
			shot_clock_remaining = 0.0
			shot_clock_expired.emit(shot_clock_team)
			# Trigger possession change to other team
			var receiving := 1 if shot_clock_team == 2 else 2
			last_scoring_team = shot_clock_team  # Reuse for possession tracking
			score_pause_timer = 0.01  # Near-instant reset
			possession_reset.emit(receiving)

	# Game clock
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		clock_updated.emit(time_remaining)
		_end_match()
	else:
		clock_updated.emit(time_remaining)


func _end_match() -> void:
	winner = get_winner()
	_change_state(MatchState.BUZZER)
	# Brief pause then show results
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(_show_results)


func _show_results() -> void:
	_change_state(MatchState.RESULTS)
	match_ended.emit(winner)


func _change_state(new_state: MatchState) -> void:
	var old := state
	state = new_state
	if new_state == MatchState.COUNTDOWN:
		countdown_remaining = GameConfig.data.countdown_duration
		_last_countdown_second = -1
	game_state_changed.emit(old, new_state)

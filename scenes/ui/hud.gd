extends CanvasLayer
## HUD displays scores, game clock, countdown, and match result messages.

@onready var team1_score_label: Label = %Team1Score
@onready var team2_score_label: Label = %Team2Score
@onready var clock_label: Label = %Clock
@onready var message_label: Label = %Message


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.clock_updated.connect(_on_clock_updated)
	GameManager.countdown_tick.connect(_on_countdown_tick)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.match_ended.connect(_on_match_ended)
	_reset_display()


func _reset_display() -> void:
	team1_score_label.text = "0"
	team2_score_label.text = "0"
	clock_label.text = _format_time(GameConfig.data.match_duration)
	message_label.text = ""


func _on_score_changed(team: int, new_score: int) -> void:
	if team == 1:
		team1_score_label.text = str(new_score)
	elif team == 2:
		team2_score_label.text = str(new_score)


func _on_clock_updated(time_remaining: float) -> void:
	clock_label.text = _format_time(time_remaining)


func _on_countdown_tick(seconds_left: int) -> void:
	message_label.text = str(seconds_left)


func _on_game_state_changed(_old_state: GameManager.MatchState, new_state: GameManager.MatchState) -> void:
	match new_state:
		GameManager.MatchState.PREGAME:
			_reset_display()
			message_label.text = "PRESS R TO START"
		GameManager.MatchState.COUNTDOWN:
			message_label.text = ""
		GameManager.MatchState.PLAYING:
			message_label.text = ""
		GameManager.MatchState.BUZZER:
			message_label.text = "GAME OVER"
		GameManager.MatchState.RESULTS:
			pass # handled by _on_match_ended


func _on_match_ended(winner: int) -> void:
	match winner:
		0:
			message_label.text = "DRAW!\nPress R to rematch"
		1:
			message_label.text = "TEAM 1 WINS!\nPress R to rematch"
		2:
			message_label.text = "TEAM 2 WINS!\nPress R to rematch"


func _format_time(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%d:%02d" % [mins, secs]

extends CanvasLayer
## HUD displays scores, game clock, countdown, match result messages,
## shot feedback, fire indicator, and possession indicator.

@onready var team1_score_label: Label = %Team1Score
@onready var team2_score_label: Label = %Team2Score
@onready var clock_label: Label = %Clock
@onready var message_label: Label = %Message
@onready var shot_feedback_label: Label = %ShotFeedback
@onready var fire_indicator_label: Label = %FireIndicator
@onready var possession_label: Label = %PossessionIndicator
@onready var feedback_timer: Timer = %FeedbackTimer

var _fire_players: Array[Player] = []
var commentary: CommentarySystem


func _ready() -> void:
	commentary = CommentarySystem.new()
	commentary.name = "CommentarySystem"
	add_child(commentary)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.clock_updated.connect(_on_clock_updated)
	GameManager.countdown_tick.connect(_on_countdown_tick)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.match_ended.connect(_on_match_ended)
	if feedback_timer:
		feedback_timer.timeout.connect(_on_feedback_timer_timeout)
	_reset_display()


func _reset_display() -> void:
	team1_score_label.text = "0"
	team2_score_label.text = "0"
	clock_label.text = _format_time(GameConfig.data.match_duration)
	message_label.text = ""
	shot_feedback_label.text = ""
	fire_indicator_label.text = ""
	possession_label.text = ""


func _on_score_changed(team: int, new_score: int) -> void:
	if team == 1:
		team1_score_label.text = str(new_score)
		_flash_label(team1_score_label)
	elif team == 2:
		team2_score_label.text = str(new_score)
		_flash_label(team2_score_label)


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


# -- Shot Feedback --

func show_shot_feedback(text: String) -> void:
	shot_feedback_label.text = text
	if feedback_timer:
		feedback_timer.start()


func on_shot_made(points: int) -> void:
	var event_type := "shot_3pt" if points >= 3 else "shot_2pt"
	show_shot_feedback(commentary.track_event(event_type))


func on_dunk_made() -> void:
	show_shot_feedback(commentary.track_event("dunk"))


func on_shot_blocked() -> void:
	show_shot_feedback(commentary.track_event("block"))
	commentary.reset_streak("dunk")
	commentary.reset_streak("shot_2pt")
	commentary.reset_streak("shot_3pt")


func on_ball_stolen() -> void:
	show_shot_feedback(commentary.track_event("steal"))
	commentary.reset_streak("dunk")
	commentary.reset_streak("shot_2pt")
	commentary.reset_streak("shot_3pt")


func on_shot_missed() -> void:
	commentary.reset_streak("dunk")
	commentary.reset_streak("shot_2pt")
	commentary.reset_streak("shot_3pt")


func _on_feedback_timer_timeout() -> void:
	shot_feedback_label.text = ""


# -- Fire Indicator --

func on_player_caught_fire(player: Player) -> void:
	if player and player not in _fire_players:
		_fire_players.append(player)
	_update_fire_display()


func on_player_fire_ended(player: Player) -> void:
	_fire_players.erase(player)
	_update_fire_display()


func _update_fire_display() -> void:
	if _fire_players.size() > 0:
		fire_indicator_label.text = commentary.get_commentary("on_fire")
	else:
		fire_indicator_label.text = ""


# -- Possession Indicator --

func update_possession(team: int) -> void:
	match team:
		1:
			possession_label.text = "< TEAM 1"
		2:
			possession_label.text = "TEAM 2 >"
		_:
			possession_label.text = ""


func _flash_label(label: Label) -> Tween:
	var config := GameConfig.data
	label.pivot_offset = label.size * 0.5
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * config.score_flash_scale, config.score_flash_duration * 0.5)
	tween.tween_property(label, "scale", Vector2.ONE, config.score_flash_duration * 0.5)
	return tween


func _format_time(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%d:%02d" % [mins, secs]

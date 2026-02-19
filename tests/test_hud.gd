extends GutTest

var _hud: CanvasLayer
var _config: Node
var _manager: Node


func before_each() -> void:
	_config = load("res://scripts/autoload/game_config.gd").new()
	_config.name = "GameConfig"
	add_child(_config)
	_manager = load("res://scripts/autoload/game_manager.gd").new()
	_manager.name = "GameManager"
	add_child(_manager)
	_hud = load("res://scenes/ui/hud.tscn").instantiate()
	add_child(_hud)


func after_each() -> void:
	_hud.queue_free()
	_manager.queue_free()
	_config.queue_free()


# -- Helpers --

func _get_label(name: String) -> Label:
	return _hud.get_node("%" + name) as Label


# =============================================================================
# Score display tests
# =============================================================================

func test_score_updates_team1() -> void:
	_hud._on_score_changed(1, 10)
	assert_eq(_get_label("Team1Score").text, "10")

func test_score_updates_team2() -> void:
	_hud._on_score_changed(2, 7)
	assert_eq(_get_label("Team2Score").text, "7")


# =============================================================================
# Clock display tests
# =============================================================================

func test_clock_formats_correctly() -> void:
	_hud._on_clock_updated(90.0)
	assert_eq(_get_label("Clock").text, "1:30")

func test_clock_formats_zero() -> void:
	_hud._on_clock_updated(0.0)
	assert_eq(_get_label("Clock").text, "0:00")


# =============================================================================
# Shot feedback tests
# =============================================================================

func test_shot_made_shows_swish() -> void:
	_hud.on_shot_made(2)
	assert_eq(_get_label("ShotFeedback").text, "SWISH!")

func test_three_pointer_shows_downtown() -> void:
	_hud.on_shot_made(3)
	assert_eq(_get_label("ShotFeedback").text, "FROM DOWNTOWN!")

func test_dunk_shows_slam_dunk() -> void:
	_hud.on_dunk_made()
	assert_eq(_get_label("ShotFeedback").text, "SLAM DUNK!")

func test_blocked_shows_blocked() -> void:
	_hud.on_shot_blocked()
	assert_eq(_get_label("ShotFeedback").text, "BLOCKED!")

func test_stolen_shows_stolen() -> void:
	_hud.on_ball_stolen()
	assert_eq(_get_label("ShotFeedback").text, "STOLEN!")

func test_feedback_clears_on_timer() -> void:
	_hud.on_shot_made(2)
	assert_eq(_get_label("ShotFeedback").text, "SWISH!")
	_hud._on_feedback_timer_timeout()
	assert_eq(_get_label("ShotFeedback").text, "")


# =============================================================================
# Fire indicator tests
# =============================================================================

func test_fire_indicator_shows_on_fire() -> void:
	var p := Player.new()
	_hud.on_player_caught_fire(p)
	assert_eq(_get_label("FireIndicator").text, "HE'S ON FIRE!")
	p.queue_free()

func test_fire_indicator_hides_on_end() -> void:
	var p := Player.new()
	_hud.on_player_caught_fire(p)
	_hud.on_player_fire_ended(p)
	assert_eq(_get_label("FireIndicator").text, "")
	p.queue_free()

func test_fire_stays_if_multiple_players() -> void:
	var p1 := Player.new()
	var p2 := Player.new()
	_hud.on_player_caught_fire(p1)
	_hud.on_player_caught_fire(p2)
	_hud.on_player_fire_ended(p1)
	assert_eq(_get_label("FireIndicator").text, "HE'S ON FIRE!",
		"Should stay visible while any player is on fire")
	p1.queue_free()
	p2.queue_free()


# =============================================================================
# Possession indicator tests
# =============================================================================

func test_possession_team1() -> void:
	_hud.update_possession(1)
	assert_eq(_get_label("PossessionIndicator").text, "< TEAM 1")

func test_possession_team2() -> void:
	_hud.update_possession(2)
	assert_eq(_get_label("PossessionIndicator").text, "TEAM 2 >")

func test_possession_clears() -> void:
	_hud.update_possession(1)
	_hud.update_possession(0)
	assert_eq(_get_label("PossessionIndicator").text, "")


# =============================================================================
# Game state tests
# =============================================================================

func test_pregame_message() -> void:
	_hud._on_game_state_changed(GameManager.MatchState.RESULTS, GameManager.MatchState.PREGAME)
	assert_eq(_get_label("Message").text, "PRESS R TO START")

func test_results_team1_wins() -> void:
	_hud._on_match_ended(1)
	assert_eq(_get_label("Message").text, "TEAM 1 WINS!\nPress R to rematch")

func test_results_draw() -> void:
	_hud._on_match_ended(0)
	assert_eq(_get_label("Message").text, "DRAW!\nPress R to rematch")

func test_reset_clears_all() -> void:
	_hud._on_score_changed(1, 5)
	_hud.on_shot_made(2)
	_hud.update_possession(1)
	_hud._reset_display()
	assert_eq(_get_label("Team1Score").text, "0")
	assert_eq(_get_label("ShotFeedback").text, "")
	assert_eq(_get_label("PossessionIndicator").text, "")

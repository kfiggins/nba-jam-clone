extends GutTest

var _manager: Node
var _config: Node


func before_each() -> void:
	# Create a fresh GameConfig autoload
	_config = load("res://scripts/autoload/game_config.gd").new()
	_config.name = "GameConfig"
	add_child(_config)

	# Create a fresh GameManager autoload
	_manager = load("res://scripts/autoload/game_manager.gd").new()
	_manager.name = "GameManager"
	add_child(_manager)


func after_each() -> void:
	_manager.queue_free()
	_config.queue_free()


# -- Initial State --

func test_initial_state_is_pregame() -> void:
	assert_eq(_manager.state, _manager.MatchState.PREGAME)


func test_initial_scores_are_zero() -> void:
	assert_eq(_manager.get_score(1), 0)
	assert_eq(_manager.get_score(2), 0)


# -- Score Tracking --

func test_add_score_team1() -> void:
	_manager.state = _manager.MatchState.PLAYING
	_manager.add_score(1)
	assert_eq(_manager.get_score(1), 2, "Team 1 should have 2 points")


func test_add_score_team2() -> void:
	_manager.state = _manager.MatchState.PLAYING
	_manager.add_score(2)
	assert_eq(_manager.get_score(2), 2, "Team 2 should have 2 points")


func test_add_score_custom_points() -> void:
	_manager.state = _manager.MatchState.PLAYING
	_manager.add_score(1, 3)
	assert_eq(_manager.get_score(1), 3, "Team 1 should have 3 points")


func test_add_score_accumulates() -> void:
	_manager.state = _manager.MatchState.PLAYING
	_manager.add_score(1)
	_manager.add_score(1)
	_manager.add_score(1, 3)
	assert_eq(_manager.get_score(1), 7, "Team 1 should have 2+2+3=7 points")


func test_add_score_only_during_playing() -> void:
	# Should not add score in PREGAME
	_manager.add_score(1)
	assert_eq(_manager.get_score(1), 0, "Should not score in PREGAME")


func test_add_score_invalid_team() -> void:
	_manager.state = _manager.MatchState.PLAYING
	_manager.add_score(0)
	_manager.add_score(3)
	assert_eq(_manager.get_score(1), 0)
	assert_eq(_manager.get_score(2), 0)


func test_get_score_invalid_team_returns_zero() -> void:
	assert_eq(_manager.get_score(0), 0)
	assert_eq(_manager.get_score(3), 0)


# -- Score Signal --

func test_score_changed_signal() -> void:
	watch_signals(_manager)
	_manager.state = _manager.MatchState.PLAYING
	_manager.add_score(1)
	assert_signal_emitted(_manager, "score_changed")


# -- Winner Determination --

func test_get_winner_team1() -> void:
	_manager.state = _manager.MatchState.PLAYING
	_manager.add_score(1, 10)
	_manager.add_score(2, 5)
	assert_eq(_manager.get_winner(), 1)


func test_get_winner_team2() -> void:
	_manager.state = _manager.MatchState.PLAYING
	_manager.add_score(1, 5)
	_manager.add_score(2, 10)
	assert_eq(_manager.get_winner(), 2)


func test_get_winner_draw() -> void:
	_manager.state = _manager.MatchState.PLAYING
	_manager.add_score(1, 10)
	_manager.add_score(2, 10)
	assert_eq(_manager.get_winner(), 0)


# -- Match Flow --

func test_start_match_resets_scores() -> void:
	_manager.state = _manager.MatchState.PLAYING
	_manager.add_score(1, 10)
	_manager.add_score(2, 5)
	_manager.start_match()
	assert_eq(_manager.get_score(1), 0)
	assert_eq(_manager.get_score(2), 0)


func test_start_match_sets_countdown() -> void:
	_manager.start_match()
	assert_eq(_manager.state, _manager.MatchState.COUNTDOWN)


func test_start_match_sets_time() -> void:
	_manager.start_match()
	assert_eq(_manager.time_remaining, _config.data.match_duration)


func test_state_changed_signal_on_start() -> void:
	watch_signals(_manager)
	_manager.start_match()
	assert_signal_emitted(_manager, "game_state_changed")


# -- Timer --

func test_get_time_remaining() -> void:
	_manager.time_remaining = 60.0
	assert_eq(_manager.get_time_remaining(), 60.0)


# -- Restart --

func test_restart_resets_match() -> void:
	_manager.state = _manager.MatchState.PLAYING
	_manager.add_score(1, 10)
	_manager.add_score(2, 5)
	_manager.state = _manager.MatchState.RESULTS
	_manager.restart()
	assert_eq(_manager.get_score(1), 0)
	assert_eq(_manager.get_score(2), 0)
	assert_eq(_manager.state, _manager.MatchState.COUNTDOWN)

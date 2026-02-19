extends GutTest

var _commentary: CommentarySystem


func before_each() -> void:
	_commentary = CommentarySystem.new()
	_commentary.name = "CommentarySystem"
	add_child(_commentary)


func after_each() -> void:
	_commentary.queue_free()


# =============================================================================
# get_commentary basics
# =============================================================================

func test_get_commentary_dunk_tier_0_returns_nonempty() -> void:
	var text := _commentary.get_commentary("dunk", 0)
	assert_true(text.length() > 0, "Dunk tier 0 should return non-empty text")


func test_get_commentary_dunk_tier_2_returns_nonempty() -> void:
	var text := _commentary.get_commentary("dunk", 2)
	assert_true(text.length() > 0, "Dunk tier 2 should return non-empty text")


func test_get_commentary_clamped_to_max_tier() -> void:
	var text := _commentary.get_commentary("dunk", 99)
	assert_true(text.length() > 0, "Should clamp to last tier, not crash")


func test_get_commentary_nonexistent_event_returns_empty() -> void:
	var text := _commentary.get_commentary("nonexistent")
	assert_eq(text, "")


# =============================================================================
# Tier 0 pools contain expected phrases
# =============================================================================

func test_dunk_tier_0_phrases() -> void:
	var expected := ["SLAM DUNK!", "BOOMSHAKALAKA!", "THROWS IT DOWN!"]
	var text := _commentary.get_commentary("dunk", 0)
	assert_true(text in expected, "Dunk tier 0 should be one of: %s, got: %s" % [expected, text])


func test_shot_2pt_tier_0_phrases() -> void:
	var expected := ["SWISH!", "NOTHING BUT NET!", "GOOD!"]
	var text := _commentary.get_commentary("shot_2pt", 0)
	assert_true(text in expected, "Shot 2pt tier 0 should be one of: %s, got: %s" % [expected, text])


func test_shot_3pt_tier_0_phrases() -> void:
	var expected := ["FROM DOWNTOWN!", "THREE POINTER!", "LONG RANGE!"]
	var text := _commentary.get_commentary("shot_3pt", 0)
	assert_true(text in expected, "Shot 3pt tier 0 should be one of: %s, got: %s" % [expected, text])


func test_block_tier_0_phrases() -> void:
	var expected := ["BLOCKED!", "REJECTED!", "GET THAT OUTTA HERE!"]
	var text := _commentary.get_commentary("block", 0)
	assert_true(text in expected, "Block tier 0 should be one of: %s, got: %s" % [expected, text])


func test_steal_tier_0_phrases() -> void:
	var expected := ["STOLEN!", "PICKED HIS POCKET!", "TURNOVER!"]
	var text := _commentary.get_commentary("steal", 0)
	assert_true(text in expected, "Steal tier 0 should be one of: %s, got: %s" % [expected, text])


func test_on_fire_phrases() -> void:
	var expected := ["HE'S ON FIRE!", "HE'S HEATING UP!", "FEELING IT!"]
	var text := _commentary.get_commentary("on_fire", 0)
	assert_true(text in expected, "On fire should be one of: %s, got: %s" % [expected, text])


# =============================================================================
# Streak tracking
# =============================================================================

func test_track_event_increments_streak() -> void:
	_commentary.track_event("dunk")
	assert_eq(_commentary.get_streak("dunk"), 1)
	_commentary.track_event("dunk")
	assert_eq(_commentary.get_streak("dunk"), 2)


func test_track_event_returns_nonempty_text() -> void:
	var text := _commentary.track_event("dunk")
	assert_true(text.length() > 0, "track_event should return commentary text")


func test_reset_streak_clears_counter() -> void:
	_commentary.track_event("dunk")
	_commentary.track_event("dunk")
	_commentary.reset_streak("dunk")
	assert_eq(_commentary.get_streak("dunk"), 0)


func test_get_streak_default_is_zero() -> void:
	assert_eq(_commentary.get_streak("dunk"), 0)


func test_streak_advances_tier() -> void:
	# Tier 0 phrases (dunk)
	var tier0_expected := ["SLAM DUNK!", "BOOMSHAKALAKA!", "THROWS IT DOWN!"]
	# Tier 1 phrases (dunk)
	var tier1_expected := ["ANOTHER SLAM!", "HE CAN'T BE STOPPED!", "MONSTER JAM!"]
	# First call = tier 0
	var text0 := _commentary.track_event("dunk")
	assert_true(text0 in tier0_expected, "First dunk should use tier 0")
	# Second call = tier 1
	var text1 := _commentary.track_event("dunk")
	assert_true(text1 in tier1_expected, "Second dunk should use tier 1")

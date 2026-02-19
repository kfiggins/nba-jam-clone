class_name CommentarySystem
extends Node
## Manages tiered commentary phrases that escalate with consecutive events.
## Each event type has multiple tiers of phrases; streaks advance the tier.

var _phrase_pools: Dictionary = {}
var _streak_counters: Dictionary = {}


func _ready() -> void:
	_init_phrase_pools()


func track_event(event_type: String) -> String:
	if not _streak_counters.has(event_type):
		_streak_counters[event_type] = 0
	_streak_counters[event_type] += 1
	return get_commentary(event_type, _streak_counters[event_type] - 1)


func get_commentary(event_type: String, streak: int = 0) -> String:
	var pool: Array = _phrase_pools.get(event_type, [])
	if pool.is_empty():
		return ""
	var tier := clampi(streak, 0, pool.size() - 1)
	var tier_phrases: Array = pool[tier]
	return tier_phrases[randi() % tier_phrases.size()]


func reset_streak(event_type: String) -> void:
	_streak_counters[event_type] = 0


func get_streak(event_type: String) -> int:
	return _streak_counters.get(event_type, 0)


func _init_phrase_pools() -> void:
	_phrase_pools["dunk"] = [
		["SLAM DUNK!", "BOOMSHAKALAKA!", "THROWS IT DOWN!"],
		["ANOTHER SLAM!", "HE CAN'T BE STOPPED!", "MONSTER JAM!"],
		["IS IT THE SHOES?!", "UNBELIEVABLE!", "THE CROWD GOES WILD!"],
	]
	_phrase_pools["shot_2pt"] = [
		["SWISH!", "NOTHING BUT NET!", "GOOD!"],
		["HE'S HEATING UP!", "ANOTHER BUCKET!", "TOO EASY!"],
		["ON FIRE!", "UNSTOPPABLE!", "THE HAND IS HOT!"],
	]
	_phrase_pools["shot_3pt"] = [
		["FROM DOWNTOWN!", "THREE POINTER!", "LONG RANGE!"],
		["HE'S A SNIPER!", "RAINING THREES!", "DEEP!"],
		["CAN'T MISS!", "LIGHTS OUT!", "ARE YOU KIDDING ME?!"],
	]
	_phrase_pools["block"] = [
		["BLOCKED!", "REJECTED!", "GET THAT OUTTA HERE!"],
		["ANOTHER BLOCK!", "SWAT PARTY!", "NOT IN MY HOUSE!"],
	]
	_phrase_pools["steal"] = [
		["STOLEN!", "PICKED HIS POCKET!", "TURNOVER!"],
		["ANOTHER STEAL!", "STICKY FINGERS!", "LOCKDOWN!"],
	]
	_phrase_pools["on_fire"] = [
		["HE'S ON FIRE!", "HE'S HEATING UP!", "FEELING IT!"],
	]

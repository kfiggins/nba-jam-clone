extends Node
## Global configuration singleton.
## Loads tuning values from a GameConfigData resource and exposes them globally.

const DEFAULT_CONFIG_PATH := "res://resources/default_config.tres"

var data: GameConfigData


func _ready() -> void:
	data = _load_config(DEFAULT_CONFIG_PATH)


func _load_config(path: String) -> GameConfigData:
	if ResourceLoader.exists(path):
		var loaded := load(path)
		if loaded is GameConfigData:
			return loaded
	push_warning("GameConfig: Could not load '%s', using defaults." % path)
	return GameConfigData.new()


func reload(path: String = DEFAULT_CONFIG_PATH) -> void:
	data = _load_config(path)

extends Node
## Stub audio manager. Emits signals when SFX are requested so systems
## can react (and tests can verify). Actual playback will be added when
## audio files are available.

signal sfx_requested(sfx_name: String)


func play_sfx(sfx_name: String) -> void:
	sfx_requested.emit(sfx_name)

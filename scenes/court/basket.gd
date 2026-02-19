class_name Basket
extends Node2D
## Basketball hoop with a rim position, pseudo-3D height, and rim shake effect.

## Height of the rim in pseudo-3D space.
var rim_height: float = 120.0


func _ready() -> void:
	add_to_group("basket")


func rim_shake() -> Tween:
	var rim := $Rim as ColorRect
	if not rim:
		return null
	var config := GameConfig.data
	var intensity := config.rim_shake_intensity
	var duration := config.rim_shake_duration
	var step := duration / 4.0
	var tween := create_tween()
	tween.tween_property(rim, "position:x", intensity, step)
	tween.tween_property(rim, "position:x", -intensity, step)
	tween.tween_property(rim, "position:x", intensity * 0.5, step)
	tween.tween_property(rim, "position:x", 0.0, step)
	return tween

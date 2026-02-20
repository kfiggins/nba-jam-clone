class_name Basket
extends Node2D
## Basketball hoop with a rim position, pseudo-3D height, rim shake, and net swish.

## Which team scores on this basket (1 or 2).
@export var team_target: int = 1

## Height of the rim in pseudo-3D space (also controls visual elevation).
var rim_height: float = 60.0

@onready var visuals: Node2D = get_node_or_null("Visuals")


func _ready() -> void:
	add_to_group("basket")
	# Elevate the hoop visuals above ground; shadow stays at ground level
	if visuals:
		visuals.position.y = -rim_height


func rim_shake() -> Tween:
	var rim := get_node_or_null("Visuals/Rim") as Node2D
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


func net_swish() -> Tween:
	var net := get_node_or_null("Visuals/Net") as Node2D
	if not net:
		return null
	var tween := create_tween()
	# Quick stretch down then bounce back
	tween.tween_property(net, "scale:y", 1.4, 0.1)
	tween.tween_property(net, "scale:y", 0.8, 0.1)
	tween.tween_property(net, "scale:y", 1.1, 0.1)
	tween.tween_property(net, "scale:y", 1.0, 0.1)
	return tween

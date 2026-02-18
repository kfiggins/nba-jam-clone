class_name Basket
extends Node2D
## Basketball hoop with a rim position and pseudo-3D height.

## Height of the rim in pseudo-3D space.
var rim_height: float = 120.0


func _ready() -> void:
	add_to_group("basket")

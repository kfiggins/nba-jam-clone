class_name PlayerArchetype
extends Resource
## Defines a character archetype with multiplicative stat modifiers.
## A modifier of 1.0 means "use base config value". Null archetype on a Player = all 1.0.

@export var archetype_name: String = "Balanced"
@export var speed_modifier: float = 1.0
@export var jump_modifier: float = 1.0
@export var shot_accuracy_modifier: float = 1.0
@export var steal_modifier: float = 1.0
@export var dunk_modifier: float = 1.0
@export var block_modifier: float = 1.0

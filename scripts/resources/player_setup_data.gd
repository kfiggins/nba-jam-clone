class_name PlayerSetupData
extends Resource
## Configuration for spawning a player in a match.

@export var team: int = 1
@export var is_human: bool = false
@export var player_index: int = 0
@export var archetype: PlayerArchetype
@export var spawn_position: Vector2 = Vector2.ZERO

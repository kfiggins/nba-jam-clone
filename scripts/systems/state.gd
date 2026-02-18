class_name State
extends Node
## Base state class for use with StateMachine.
## Override enter(), exit(), process(), physics_process(), handle_input().

var state_machine: StateMachine


func enter() -> void:
	pass


func exit() -> void:
	pass


func process(_delta: float) -> State:
	return null


func physics_process(_delta: float) -> State:
	return null


func handle_input(_event: InputEvent) -> State:
	return null

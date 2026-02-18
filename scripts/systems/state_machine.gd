class_name StateMachine
extends Node
## Generic state machine. Add State nodes as children.
## Assign initial_state in the editor or call initialize() from code.

signal state_changed(old_state: State, new_state: State)

@export var initial_state: State

var current_state: State
var states: Dictionary = {} # name -> State


func _ready() -> void:
	_index_states()
	if initial_state:
		_enter_state(initial_state)


func _process(delta: float) -> void:
	if current_state:
		var next := current_state.process(delta)
		if next:
			change_state(next)


func _physics_process(delta: float) -> void:
	if current_state:
		var next := current_state.physics_process(delta)
		if next:
			change_state(next)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		var next := current_state.handle_input(event)
		if next:
			change_state(next)


func initialize(state: State) -> void:
	_index_states()
	_enter_state(state)


func change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	var old := current_state
	if current_state:
		current_state.exit()
	_enter_state(new_state)
	state_changed.emit(old, new_state)


func get_state(state_name: String) -> State:
	return states.get(state_name)


func _index_states() -> void:
	states.clear()
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self


func _enter_state(state: State) -> void:
	current_state = state
	current_state.enter()

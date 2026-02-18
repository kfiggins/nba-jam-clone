extends GutTest

var _machine: StateMachine
var _state_a: State
var _state_b: State


func before_each() -> void:
	_machine = StateMachine.new()
	_state_a = State.new()
	_state_a.name = "StateA"
	_state_b = State.new()
	_state_b.name = "StateB"
	_machine.add_child(_state_a)
	_machine.add_child(_state_b)
	add_child(_machine)


func after_each() -> void:
	_machine.queue_free()


func test_indexes_child_states() -> void:
	_machine.initialize(_state_a)
	assert_eq(_machine.states.size(), 2)
	assert_eq(_machine.get_state("StateA"), _state_a)
	assert_eq(_machine.get_state("StateB"), _state_b)


func test_initialize_sets_current_state() -> void:
	_machine.initialize(_state_a)
	assert_eq(_machine.current_state, _state_a)


func test_change_state() -> void:
	_machine.initialize(_state_a)
	_machine.change_state(_state_b)
	assert_eq(_machine.current_state, _state_b)


func test_change_state_same_state_does_nothing() -> void:
	_machine.initialize(_state_a)
	_machine.change_state(_state_a)
	assert_eq(_machine.current_state, _state_a)


func test_state_changed_signal() -> void:
	_machine.initialize(_state_a)
	watch_signals(_machine)
	_machine.change_state(_state_b)
	assert_signal_emitted(_machine, "state_changed")


func test_get_state_returns_null_for_unknown() -> void:
	_machine.initialize(_state_a)
	assert_null(_machine.get_state("NonExistent"))


func test_states_have_state_machine_reference() -> void:
	_machine.initialize(_state_a)
	assert_eq(_state_a.state_machine, _machine)
	assert_eq(_state_b.state_machine, _machine)

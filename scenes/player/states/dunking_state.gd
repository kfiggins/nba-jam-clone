class_name DunkingState
extends PlayerState
## Player leaps toward the basket for a guaranteed dunk/layup.
## Ball stays held during approach, then slams through on arrival.

var _dunked: bool = false
var _basket_pos: Vector2


func enter() -> void:
	player.apply_jump()
	_dunked = false
	_basket_pos = _find_basket_position()


func physics_process(delta: float) -> State:
	player.update_turbo(delta)
	player.apply_gravity(delta)

	# Move player toward basket
	if not _dunked:
		var dir_to_basket := (_basket_pos - player.global_position).normalized()
		player.velocity = dir_to_basket * GameConfig.data.dunk_speed
		player.move_and_slide()

		# Dunk when close enough and at sufficient height
		var dist := player.global_position.distance_to(_basket_pos)
		var min_height := GameConfig.data.player_jump_force * GameConfig.data.dunk_jump_threshold * 0.1
		if dist <= 25.0 and player.height >= min_height:
			_perform_dunk()

	# Land
	if player.is_on_ground():
		var dir := player.get_input_direction()
		if dir != Vector2.ZERO:
			return state_machine.get_state("Running")
		return state_machine.get_state("Idle")

	return null


func _perform_dunk() -> void:
	_dunked = true
	if player.has_ball():
		player.try_dunk()


func _find_basket_position() -> Vector2:
	for node in player.get_tree().get_nodes_in_group("basket"):
		return node.global_position
	return Vector2(1130, 360)

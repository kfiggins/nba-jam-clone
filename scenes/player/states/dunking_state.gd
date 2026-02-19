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
		if dist <= GameConfig.data.dunk_trigger_distance and player.height >= min_height:
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
	if not player.has_ball():
		return

	# Check for block before dunking
	var blocker := _find_blocker()
	if blocker:
		var ball_node := player.held_ball
		ball_node.release(Vector2.ZERO, 0.0)
		ball_node.deflect(blocker, player)
		player.apply_block_stun()
		return

	player.try_dunk()


func _find_blocker() -> Player:
	var config := GameConfig.data
	for node in player.get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p == null or p == player:
			continue
		if p.team == player.team:
			continue
		if p.is_on_ground() or p.height < config.block_height_min:
			continue
		var dist := player.global_position.distance_to(p.global_position)
		var effective_block_range := config.block_range * p.get_stat_modifier("block")
		if dist <= effective_block_range:
			return p
	return null


func _find_basket_position() -> Vector2:
	for node in player.get_tree().get_nodes_in_group("basket"):
		var basket := node as Basket
		if basket and basket.team_target == player.team:
			return basket.global_position
	# Fallback
	for node in player.get_tree().get_nodes_in_group("basket"):
		return node.global_position
	return Vector2(1130, 360)

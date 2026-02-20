class_name Ball
extends Area2D
## Basketball with pseudo-3D height, state machine, and ownership tracking.

signal owner_changed(old_owner: Player, new_owner: Player)
signal ball_stolen(stealer: Player, victim: Player)
signal ball_passed(passer: Player, target: Player)
signal ball_bounced
signal shot_taken(shooter: Player)
signal shot_made(shooter: Player, points: int)
signal shot_missed(shooter: Player)
signal dunk_made(dunker: Player, points: int)
signal shot_blocked(blocker: Player, shooter: Player)
signal steal_failed(stealer: Player, handler: Player)

## Current player holding the ball (null = loose)
var current_owner: Player = null

## Pseudo-3D height (same system as Player)
var height: float = 0.0
var height_velocity: float = 0.0

## Ground-plane velocity (used in Loose and Passed states)
var ground_velocity: Vector2 = Vector2.ZERO

## Pass target (set when entering Passed state)
var pass_target: Player = null

## Shooter reference (set when entering Shot state)
var shot_shooter: Player = null

@onready var sprite: Node2D = $Sprite
@onready var shadow: Node2D = $Shadow
@onready var state_machine: StateMachine = $StateMachine
@onready var trail: Line2D = get_node_or_null("Trail")


func _ready() -> void:
	add_to_group("ball")
	var loose := state_machine.get_state("Loose")
	if loose:
		state_machine.initialize(loose)


func _physics_process(_delta: float) -> void:
	_update_visual_height()
	_update_trail()


## Assign ball to a player. Transitions to Held state.
func pick_up(player: Player) -> void:
	var old := current_owner
	current_owner = player
	player.held_ball = self
	ground_velocity = Vector2.ZERO
	height_velocity = 0.0
	owner_changed.emit(old, player)
	state_machine.change_state(state_machine.get_state("Held"))


## Release ball into the world. Transitions to Loose state.
func release(launch_velocity: Vector2 = Vector2.ZERO, launch_height_vel: float = 0.0) -> void:
	if current_owner:
		current_owner.held_ball = null
	var old := current_owner
	current_owner = null
	ground_velocity = launch_velocity
	height_velocity = launch_height_vel
	owner_changed.emit(old, null)
	state_machine.change_state(state_machine.get_state("Loose"))


## Start a pass toward target player. Transitions to Passed state.
func start_pass(passer: Player, target: Player) -> void:
	pass_target = target
	if current_owner:
		current_owner.held_ball = null
	var old := current_owner
	current_owner = null
	ball_passed.emit(passer, target)
	owner_changed.emit(old, null)
	state_machine.change_state(state_machine.get_state("Passed"))


## Shoot the ball toward the basket. Transitions to Shot state.
func shoot(shooter: Player) -> void:
	shot_shooter = shooter
	if current_owner:
		current_owner.held_ball = null
	var old := current_owner
	current_owner = null
	shot_taken.emit(shooter)
	owner_changed.emit(old, null)
	state_machine.change_state(state_machine.get_state("Shot"))


## Dunk the ball through the basket. Guaranteed score.
func dunk(dunker: Player) -> void:
	if current_owner:
		current_owner.held_ball = null
	var old := current_owner
	current_owner = null
	var points := GameConfig.data.points_per_shot
	dunk_made.emit(dunker, points)
	GameManager.add_score(dunker.team, points)
	# Ball drops through basket from rim height
	var rim_h := 60.0
	for node in get_tree().get_nodes_in_group("basket"):
		var basket := node as Basket
		if basket and basket.team_target == dunker.team:
			rim_h = basket.rim_height
			break
	ground_velocity = Vector2(0.0, 30.0)
	height = rim_h
	height_velocity = GameConfig.data.shot_made_height_velocity
	owner_changed.emit(old, null)
	state_machine.change_state(state_machine.get_state("Loose"))


## Attempt a steal. Calculates success chance based on distance, facing, and ball exposure.
## Returns true if successful.
func attempt_steal(stealer: Player) -> bool:
	if current_owner == null:
		return false
	if current_owner.team == stealer.team:
		return false
	var chance := _calculate_steal_chance(stealer)
	var roll := randf()
	if roll < chance:
		var victim := current_owner
		ball_stolen.emit(stealer, victim)
		release(Vector2.ZERO, 100.0)
		pick_up(stealer)
		return true
	steal_failed.emit(stealer, current_owner)
	return false


## Calculate steal success probability based on distance and facing/exposure.
func _calculate_steal_chance(stealer: Player) -> float:
	var config := GameConfig.data
	var chance := config.steal_chance_base

	# Distance modifier: bonus at close range, linear falloff to 0 at steal_range
	var dist := stealer.global_position.distance_to(current_owner.global_position)
	var distance_factor := 1.0 - clampf(dist / config.steal_range, 0.0, 1.0)
	chance += config.steal_distance_max_bonus * distance_factor

	# Facing / ball exposure modifier:
	# Dot product of handler's facing and direction from handler to stealer
	# dot < 0 = stealer behind handler (ball exposed) => bonus
	# dot > 0 = stealer in front (ball shielded) => penalty
	var handler_to_stealer := (stealer.global_position - current_owner.global_position).normalized()
	if handler_to_stealer != Vector2.ZERO:
		var facing_dot := current_owner.facing_direction.dot(handler_to_stealer)
		if facing_dot < 0.0:
			chance += config.steal_facing_bonus * absf(facing_dot)
		else:
			chance += config.steal_facing_penalty * facing_dot

	# Archetype modifier
	chance *= stealer.get_stat_modifier("steal")
	return clampf(chance, 0.05, 0.95)


## Check if any opponent defender can block the shot.
## Returns the blocking player, or null if no block occurs.
func check_shot_block(shooter: Player) -> Player:
	var config := GameConfig.data
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p == null or p == shooter:
			continue
		if p.team == shooter.team:
			continue
		if p.is_on_ground() or p.height < config.block_height_min:
			continue
		var dist := global_position.distance_to(p.global_position)
		var effective_block_range := config.block_range * p.get_stat_modifier("block")
		if dist <= effective_block_range:
			return p
	return null


## Deflect the ball away from the blocker after a successful block.
func deflect(blocker: Player, shooter: Player) -> void:
	var config := GameConfig.data
	shot_blocked.emit(blocker, shooter)
	var deflect_dir := (global_position - blocker.global_position).normalized()
	if deflect_dir == Vector2.ZERO:
		deflect_dir = Vector2.RIGHT
	ground_velocity = deflect_dir * config.block_deflect_ground_speed
	height_velocity = config.block_deflect_height_vel
	state_machine.change_state(state_machine.get_state("Loose"))


## Reset ball to a position and optionally give to a receiver.
func reset_to(pos: Vector2, receiver: Player = null) -> void:
	if current_owner:
		current_owner.held_ball = null
		current_owner = null
	global_position = pos
	height = 0.0
	height_velocity = 0.0
	ground_velocity = Vector2.ZERO
	if receiver:
		pick_up(receiver)
	else:
		state_machine.change_state(state_machine.get_state("Loose"))


## Apply gravity to height with bounce.
func apply_ball_gravity(delta: float) -> void:
	height_velocity -= GameConfig.data.ball_gravity * delta
	height += height_velocity * delta
	if height <= 0.0:
		height = 0.0
		if absf(height_velocity) > 50.0:
			height_velocity = -height_velocity * GameConfig.data.ball_bounce_factor
			ball_bounced.emit()
		else:
			height_velocity = 0.0


## Find nearest teammate of the given player.
func find_pass_target(passer: Player) -> Player:
	var best: Player = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p == null or p == passer:
			continue
		if p.team != passer.team:
			continue
		var dist := passer.global_position.distance_to(p.global_position)
		if dist < best_dist:
			best_dist = dist
			best = p
	return best


## Check for nearby opponent during pass (interception).
func check_intercept() -> Player:
	var config := GameConfig.data
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p == null or p == pass_target:
			continue
		if pass_target and p.team == pass_target.team:
			continue
		var dist := global_position.distance_to(p.global_position)
		if dist <= config.ball_pickup_radius:
			return p
	return null


func _update_visual_height() -> void:
	if sprite:
		sprite.position.y = -height
	if shadow:
		shadow.position.y = 0.0
		var scale_factor := clampf(1.0 - height / 300.0, 0.5, 1.0)
		shadow.scale = Vector2(scale_factor, scale_factor)


func _update_trail() -> void:
	if not trail:
		return
	var config := GameConfig.data
	var speed := ground_velocity.length()
	if speed >= config.ball_trail_min_speed:
		var trail_pos := global_position + Vector2(0, -height)
		trail.add_point(trail_pos, 0)
		while trail.get_point_count() > config.ball_trail_length:
			trail.remove_point(trail.get_point_count() - 1)
	else:
		trail.clear_points()

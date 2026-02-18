class_name Player
extends CharacterBody2D
## Player character with pseudo-3D height for jumping.
## Position is on the ground plane; height offsets the visual sprite upward.

signal jumped
signal landed
signal turbo_changed(current: float, maximum: float)

@export var team: int = 1
@export var is_human: bool = true

## Pseudo-3D height (0 = on ground)
var height: float = 0.0
var height_velocity: float = 0.0

## Turbo / stamina
var turbo: float = 0.0

## Movement
var input_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT

## Ball interaction
var held_ball: Ball = null
var steal_cooldown_timer: float = 0.0

@onready var sprite: Node2D = $Sprite
@onready var shadow: Node2D = $Shadow
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	turbo = GameConfig.data.turbo_max
	add_to_group("players")
	# Initialize state machine (states already indexed in StateMachine._ready)
	var idle := state_machine.get_state("Idle")
	if idle:
		state_machine.initialize(idle)


func _physics_process(delta: float) -> void:
	if steal_cooldown_timer > 0.0:
		steal_cooldown_timer -= delta
	_update_visual_height()


func is_on_ground() -> bool:
	return height <= 0.0 and height_velocity <= 0.0


func get_move_speed() -> float:
	if Input.is_action_pressed("turbo") and is_human and turbo > 0.0:
		return GameConfig.data.player_sprint_speed
	return GameConfig.data.player_speed


func is_sprinting() -> bool:
	return Input.is_action_pressed("turbo") and is_human and turbo > 0.0


func update_turbo(delta: float) -> void:
	if is_sprinting():
		turbo -= GameConfig.data.turbo_drain_rate * delta
		turbo = maxf(turbo, 0.0)
	else:
		turbo += GameConfig.data.turbo_regen_rate * delta
		turbo = minf(turbo, GameConfig.data.turbo_max)
	turbo_changed.emit(turbo, GameConfig.data.turbo_max)


func apply_jump() -> void:
	height_velocity = GameConfig.data.player_jump_force
	jumped.emit()


func apply_gravity(delta: float) -> void:
	var gravity := GameConfig.data.player_gravity
	# Hang-time: reduce gravity near apex for floaty NBA Jam feel
	if absf(height_velocity) < gravity * 0.15:
		gravity *= 0.4
	height_velocity -= gravity * delta
	height += height_velocity * delta
	if height <= 0.0:
		height = 0.0
		height_velocity = 0.0
		landed.emit()


func get_input_direction() -> Vector2:
	if not is_human:
		return input_direction
	return Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()


func apply_movement(delta: float, air_control_factor: float = 1.0) -> void:
	var dir := get_input_direction()
	var speed := get_move_speed()
	var config := GameConfig.data

	if dir != Vector2.ZERO:
		facing_direction = dir
		var target_velocity := dir * speed * air_control_factor
		velocity = velocity.move_toward(target_velocity, config.player_acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, config.player_friction * delta)

	move_and_slide()


func has_ball() -> bool:
	return held_ball != null


func try_shoot() -> void:
	if held_ball == null:
		return
	held_ball.shoot(self)


func try_pass() -> void:
	if held_ball == null:
		return
	var target := held_ball.find_pass_target(self)
	if target == null:
		return
	held_ball.start_pass(self, target)


func try_steal() -> void:
	if held_ball != null:
		return
	if steal_cooldown_timer > 0.0:
		return
	steal_cooldown_timer = GameConfig.data.steal_cooldown

	var ball_node: Ball = null
	for node in get_tree().get_nodes_in_group("ball"):
		ball_node = node as Ball
		break

	if ball_node == null or ball_node.current_owner == null:
		return
	if ball_node.current_owner.team == team:
		return

	var dist := global_position.distance_to(ball_node.current_owner.global_position)
	if dist > GameConfig.data.steal_range:
		return

	ball_node.attempt_steal(self)


func _update_visual_height() -> void:
	if sprite:
		sprite.position.y = -height
	if shadow:
		shadow.position.y = 0.0
		# Shrink shadow slightly when high up
		var scale_factor := clampf(1.0 - height / 300.0, 0.5, 1.0)
		shadow.scale = Vector2(scale_factor, scale_factor)

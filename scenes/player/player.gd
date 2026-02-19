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
var block_stun_timer: float = 0.0
var steal_stun_timer: float = 0.0
var bump_slow_timer: float = 0.0
var bump_cooldown_timer: float = 0.0

## AI action flags (set by AIController, consumed by states)
var ai_shoot_requested: bool = false
var ai_pass_requested: bool = false
var ai_steal_requested: bool = false
var ai_sprint_requested: bool = false

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
	if block_stun_timer > 0.0:
		block_stun_timer -= delta
	if steal_stun_timer > 0.0:
		steal_stun_timer -= delta
	if bump_slow_timer > 0.0:
		bump_slow_timer -= delta
	if bump_cooldown_timer > 0.0:
		bump_cooldown_timer -= delta
	_update_visual_height()


func is_on_ground() -> bool:
	return height <= 0.0 and height_velocity <= 0.0


func is_block_stunned() -> bool:
	return block_stun_timer > 0.0


func apply_block_stun() -> void:
	block_stun_timer = GameConfig.data.block_stun_duration


func is_steal_stunned() -> bool:
	return steal_stun_timer > 0.0


func apply_steal_stun() -> void:
	steal_stun_timer = GameConfig.data.steal_stun_duration


func is_bumped() -> bool:
	return bump_slow_timer > 0.0


func apply_bump() -> void:
	bump_slow_timer = GameConfig.data.bump_duration


func get_move_speed() -> float:
	var speed: float
	if is_sprinting():
		speed = GameConfig.data.player_sprint_speed
	else:
		speed = GameConfig.data.player_speed
	if is_bumped():
		speed *= GameConfig.data.bump_speed_reduction
	return speed


func is_sprinting() -> bool:
	if is_human:
		return Input.is_action_pressed("turbo") and turbo > 0.0
	return ai_sprint_requested and turbo > 0.0


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

	# Body bump: check collisions with opposing ball handler
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is Player:
			var other := collider as Player
			if other.team != team and other.has_ball() and bump_cooldown_timer <= 0.0:
				other.apply_bump()
				bump_cooldown_timer = GameConfig.data.bump_cooldown


func auto_face_ball_handler() -> void:
	if not GameConfig.data.enable_auto_face_ball_handler:
		return
	if has_ball():
		return
	for node in get_tree().get_nodes_in_group("ball"):
		var ball_node := node as Ball
		if ball_node and ball_node.current_owner and ball_node.current_owner.team != team:
			var dir_to_handler := (ball_node.current_owner.global_position - global_position).normalized()
			if dir_to_handler != Vector2.ZERO:
				facing_direction = dir_to_handler
		break


func has_ball() -> bool:
	return held_ball != null


func is_in_dunk_range() -> bool:
	if not has_ball():
		return false
	for node in get_tree().get_nodes_in_group("basket"):
		var dist := global_position.distance_to(node.global_position)
		if dist <= GameConfig.data.dunk_range:
			return true
	return false


func try_shoot() -> void:
	if held_ball == null:
		return
	held_ball.shoot(self)


func try_dunk() -> void:
	if held_ball == null:
		return
	held_ball.dunk(self)


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
	if is_steal_stunned():
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

	var success := ball_node.attempt_steal(self)
	if not success:
		apply_steal_stun()


func _update_visual_height() -> void:
	if sprite:
		sprite.position.y = -height
	if shadow:
		shadow.position.y = 0.0
		# Shrink shadow slightly when high up
		var scale_factor := clampf(1.0 - height / 300.0, 0.5, 1.0)
		shadow.scale = Vector2(scale_factor, scale_factor)

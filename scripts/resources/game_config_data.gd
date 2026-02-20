class_name GameConfigData
extends Resource

# Match settings
@export var match_duration: float = 120.0 # seconds
@export var countdown_duration: float = 3.0 # seconds
@export var points_per_shot: int = 2
@export var points_per_three: int = 3
@export var enable_three_point_zone: bool = false
@export var three_point_distance: float = 400.0
@export var score_pause_duration: float = 1.0
@export var inbound_position: Vector2 = Vector2(300, 360)
@export var court_bounds: Rect2 = Rect2(80, 80, 1120, 560)
@export var enable_shot_clock: bool = false
@export var shot_clock_duration: float = 24.0

# Player movement
@export var player_speed: float = 300.0
@export var player_sprint_speed: float = 450.0
@export var player_jump_force: float = 500.0
@export var player_gravity: float = 980.0
@export var player_air_control: float = 0.3
@export var player_acceleration: float = 1200.0
@export var player_friction: float = 1000.0
@export var player_idle_velocity_threshold: float = 10.0
@export var player_hang_time_threshold: float = 0.15
@export var player_hang_time_gravity_factor: float = 0.4

# Turbo / stamina
@export var turbo_max: float = 100.0
@export var turbo_drain_rate: float = 30.0
@export var turbo_regen_rate: float = 15.0

# Ball physics
@export var ball_gravity: float = 800.0
@export var ball_bounce_factor: float = 0.6
@export var ball_pickup_radius: float = 30.0
@export var ball_ground_friction: float = 200.0
@export var ball_pickup_height_threshold: float = 30.0
@export var ball_hold_offset: Vector2 = Vector2(15.0, -5.0)
@export var ball_hold_height_offset: float = 20.0
@export var pass_speed: float = 600.0
@export var pass_arc_height: float = 40.0
@export var pass_initial_height: float = 20.0
@export var pass_arc_curve_factor: float = 4.0
@export var steal_range: float = 40.0

# Shooting
@export var shot_success_base: float = 0.5
@export var shot_success_close: float = 0.85
@export var shot_perfect_window: float = 0.15 # seconds
@export var shot_perfect_bonus: float = 0.25
@export var shot_speed: float = 500.0
@export var shot_arc_height: float = 200.0
@export var shot_arc_curve_factor: float = 4.0
@export var shot_close_range: float = 200.0
@export var shot_release_delay: float = 0.15 # seconds before ball released during jump
@export var shot_resolution_distance: float = 15.0
@export var shot_made_drop_velocity: Vector2 = Vector2(0.0, 20.0)
@export var shot_made_height: float = 100.0
@export var shot_made_height_velocity: float = -200.0
@export var shot_miss_bounce_min: float = 100.0
@export var shot_miss_bounce_max: float = 200.0
@export var shot_miss_rim_height_factor: float = 0.8

# Dunk
@export var dunk_range: float = 100.0
@export var dunk_jump_threshold: float = 0.6
@export var dunk_speed: float = 400.0
@export var dunk_trigger_distance: float = 25.0

# Defense
@export var steal_chance_base: float = 0.3
@export var steal_cooldown: float = 0.5
@export var steal_stun_duration: float = 0.3
@export var block_window: float = 0.3
@export var block_range: float = 60.0
@export var block_height_min: float = 30.0
@export var block_stun_duration: float = 0.4
@export var block_deflect_height_vel: float = 150.0
@export var block_deflect_ground_speed: float = 200.0
@export var enable_goaltending: bool = true
@export var goaltending_progress: float = 0.6
@export var steal_facing_bonus: float = 0.25
@export var steal_facing_penalty: float = -0.15
@export var steal_distance_max_bonus: float = 0.15
@export var bump_speed_reduction: float = 0.4
@export var bump_duration: float = 0.3
@export var bump_cooldown: float = 0.5
@export var enable_auto_face_ball_handler: bool = true

# AI
@export var ai_reaction_speed: float = 0.3
@export var ai_shot_accuracy: float = 0.5
@export var ai_steal_chance: float = 0.3
@export var ai_aggression: float = 0.5
@export var ai_shoot_range: float = 250.0
@export var ai_open_threshold: float = 60.0
@export var ai_pass_advantage: float = 50.0
@export var ai_block_react_range: float = 80.0
@export var ai_steal_cooldown: float = 1.0
@export var ai_recovery_threshold: float = 30.0
@export var ai_reaction_speed_variance: float = 0.05
@export var ai_movement_stop_distance: float = 20.0
@export var ai_guard_distance: float = 30.0

# Camera
@export var camera_smooth_speed: float = 5.0
@export var camera_zoom_base: float = 1.0
@export var camera_zoom_action: float = 1.15
@export var camera_action_range: float = 200.0
@export var camera_zoom_smooth_speed: float = 3.0
@export var camera_offset_x: float = 50.0
@export var camera_focus_weight: float = 0.7
@export var camera_basket_weight: float = 0.3

# On Fire
@export var fire_streak_threshold: int = 3
@export var fire_shot_bonus: float = 0.3

# Replay
@export var replay_duration: float = 1.5
@export var replay_slow_mo_scale: float = 0.3
@export var camera_replay_zoom: float = 1.3
@export var enable_dunk_replay: bool = true

# Juice / Feedback
@export var shake_dunk_intensity: float = 8.0
@export var shake_dunk_duration: float = 0.3
@export var shake_block_intensity: float = 6.0
@export var shake_block_duration: float = 0.25
@export var ball_trail_length: int = 8
@export var ball_trail_min_speed: float = 300.0
@export var rim_shake_intensity: float = 4.0
@export var rim_shake_duration: float = 0.2
@export var score_flash_scale: float = 1.5
@export var score_flash_duration: float = 0.3

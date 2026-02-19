class_name GameConfigData
extends Resource

# Match settings
@export var match_duration: float = 120.0 # seconds
@export var countdown_duration: float = 3.0 # seconds
@export var points_per_shot: int = 2
@export var points_per_three: int = 3
@export var enable_three_point_zone: bool = false

# Player movement
@export var player_speed: float = 300.0
@export var player_sprint_speed: float = 450.0
@export var player_jump_force: float = 500.0
@export var player_gravity: float = 980.0
@export var player_air_control: float = 0.3
@export var player_acceleration: float = 1200.0
@export var player_friction: float = 1000.0

# Turbo / stamina
@export var turbo_max: float = 100.0
@export var turbo_drain_rate: float = 30.0
@export var turbo_regen_rate: float = 15.0

# Ball physics
@export var ball_gravity: float = 800.0
@export var ball_bounce_factor: float = 0.6
@export var ball_pickup_radius: float = 30.0
@export var pass_speed: float = 600.0
@export var pass_arc_height: float = 40.0
@export var steal_range: float = 40.0

# Shooting
@export var shot_success_base: float = 0.5
@export var shot_success_close: float = 0.85
@export var shot_perfect_window: float = 0.15 # seconds
@export var shot_perfect_bonus: float = 0.25
@export var shot_speed: float = 500.0
@export var shot_arc_height: float = 200.0
@export var shot_close_range: float = 200.0
@export var shot_release_delay: float = 0.15 # seconds before ball released during jump
@export var shot_miss_bounce_min: float = 100.0
@export var shot_miss_bounce_max: float = 200.0

# Dunk
@export var dunk_range: float = 100.0
@export var dunk_jump_threshold: float = 0.6
@export var dunk_speed: float = 400.0

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

# On Fire
@export var fire_streak_threshold: int = 3
@export var fire_shot_bonus: float = 0.3

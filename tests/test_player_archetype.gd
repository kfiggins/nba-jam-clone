extends GutTest

var _config: Node
var _manager: Node


func before_each() -> void:
	_config = load("res://scripts/autoload/game_config.gd").new()
	_config.name = "GameConfig"
	add_child(_config)
	_manager = load("res://scripts/autoload/game_manager.gd").new()
	_manager.name = "GameManager"
	add_child(_manager)


func after_each() -> void:
	_manager.queue_free()
	_config.queue_free()


func _make_player() -> Player:
	var p := Player.new()
	p.name = "TestPlayer"
	p.is_human = false
	var sprite := Node2D.new()
	sprite.name = "Sprite"
	p.add_child(sprite)
	var shadow := Node2D.new()
	shadow.name = "Shadow"
	p.add_child(shadow)
	var sm := StateMachine.new()
	sm.name = "StateMachine"
	p.add_child(sm)
	add_child(p)
	return p


# =============================================================================
# Archetype resource defaults
# =============================================================================

func test_archetype_resource_defaults() -> void:
	var arch := PlayerArchetype.new()
	assert_eq(arch.archetype_name, "Balanced")
	assert_eq(arch.speed_modifier, 1.0)
	assert_eq(arch.jump_modifier, 1.0)
	assert_eq(arch.shot_accuracy_modifier, 1.0)
	assert_eq(arch.steal_modifier, 1.0)
	assert_eq(arch.dunk_modifier, 1.0)
	assert_eq(arch.block_modifier, 1.0)


# =============================================================================
# get_stat_modifier with no archetype
# =============================================================================

func test_no_archetype_returns_1_for_all_stats() -> void:
	var p := _make_player()
	assert_eq(p.get_stat_modifier("speed"), 1.0)
	assert_eq(p.get_stat_modifier("jump"), 1.0)
	assert_eq(p.get_stat_modifier("shot_accuracy"), 1.0)
	assert_eq(p.get_stat_modifier("steal"), 1.0)
	assert_eq(p.get_stat_modifier("dunk"), 1.0)
	assert_eq(p.get_stat_modifier("block"), 1.0)
	p.queue_free()


func test_unknown_stat_returns_1() -> void:
	var p := _make_player()
	assert_eq(p.get_stat_modifier("nonexistent"), 1.0)
	p.queue_free()


# =============================================================================
# get_stat_modifier with archetype
# =============================================================================

func test_speed_archetype_modifier() -> void:
	var p := _make_player()
	var arch := PlayerArchetype.new()
	arch.speed_modifier = 1.3
	p.archetype = arch
	assert_eq(p.get_stat_modifier("speed"), 1.3)
	p.queue_free()


func test_jump_archetype_modifier() -> void:
	var p := _make_player()
	var arch := PlayerArchetype.new()
	arch.jump_modifier = 1.2
	p.archetype = arch
	assert_eq(p.get_stat_modifier("jump"), 1.2)
	p.queue_free()


func test_shot_accuracy_archetype_modifier() -> void:
	var p := _make_player()
	var arch := PlayerArchetype.new()
	arch.shot_accuracy_modifier = 1.35
	p.archetype = arch
	assert_eq(p.get_stat_modifier("shot_accuracy"), 1.35)
	p.queue_free()


func test_steal_archetype_modifier() -> void:
	var p := _make_player()
	var arch := PlayerArchetype.new()
	arch.steal_modifier = 1.1
	p.archetype = arch
	assert_eq(p.get_stat_modifier("steal"), 1.1)
	p.queue_free()


func test_dunk_archetype_modifier() -> void:
	var p := _make_player()
	var arch := PlayerArchetype.new()
	arch.dunk_modifier = 0.8
	p.archetype = arch
	assert_eq(p.get_stat_modifier("dunk"), 0.8)
	p.queue_free()


func test_block_archetype_modifier() -> void:
	var p := _make_player()
	var arch := PlayerArchetype.new()
	arch.block_modifier = 1.3
	p.archetype = arch
	assert_eq(p.get_stat_modifier("block"), 1.3)
	p.queue_free()


# =============================================================================
# Speed modifier affects get_move_speed
# =============================================================================

func test_speed_modifier_increases_move_speed() -> void:
	var p := _make_player()
	var base_speed := p.get_move_speed()
	var arch := PlayerArchetype.new()
	arch.speed_modifier = 1.3
	p.archetype = arch
	var modified_speed := p.get_move_speed()
	assert_true(modified_speed > base_speed, "Speed should increase with speed modifier > 1.0")
	p.queue_free()


func test_speed_modifier_decreases_move_speed() -> void:
	var p := _make_player()
	var base_speed := p.get_move_speed()
	var arch := PlayerArchetype.new()
	arch.speed_modifier = 0.85
	p.archetype = arch
	var modified_speed := p.get_move_speed()
	assert_true(modified_speed < base_speed, "Speed should decrease with speed modifier < 1.0")
	p.queue_free()


# =============================================================================
# Jump modifier affects apply_jump
# =============================================================================

func test_jump_modifier_affects_height_velocity() -> void:
	var p := _make_player()
	var base_force := GameConfig.data.player_jump_force
	var arch := PlayerArchetype.new()
	arch.jump_modifier = 1.2
	p.archetype = arch
	p.apply_jump()
	assert_eq(p.height_velocity, base_force * 1.2)
	p.queue_free()


# =============================================================================
# Loaded archetype presets
# =============================================================================

func test_balanced_preset_all_ones() -> void:
	var arch: PlayerArchetype = load("res://resources/archetypes/balanced.tres")
	assert_eq(arch.archetype_name, "Balanced")
	assert_eq(arch.speed_modifier, 1.0)
	assert_eq(arch.jump_modifier, 1.0)
	assert_eq(arch.shot_accuracy_modifier, 1.0)

func test_speed_preset_values() -> void:
	var arch: PlayerArchetype = load("res://resources/archetypes/speed.tres")
	assert_eq(arch.archetype_name, "Speed")
	assert_eq(arch.speed_modifier, 1.3)
	assert_eq(arch.shot_accuracy_modifier, 0.85)

func test_power_preset_values() -> void:
	var arch: PlayerArchetype = load("res://resources/archetypes/power.tres")
	assert_eq(arch.archetype_name, "Power")
	assert_eq(arch.dunk_modifier, 1.3)
	assert_eq(arch.block_modifier, 1.3)

func test_sharpshooter_preset_values() -> void:
	var arch: PlayerArchetype = load("res://resources/archetypes/sharpshooter.tres")
	assert_eq(arch.archetype_name, "Sharpshooter")
	assert_eq(arch.shot_accuracy_modifier, 1.35)
	assert_eq(arch.speed_modifier, 0.95)

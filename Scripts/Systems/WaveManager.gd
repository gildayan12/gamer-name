extends Node

# State Signals
signal wave_started(wave_num: int)
signal wave_completed
signal upgrade_phase_started

# Config
@export var spawn_interval: float = 2.0
@export var base_enemies_per_wave: int = 10
@export var spawn_radius: float = 600.0

# State
var current_wave: int = 1
var enemies_remaining: int = 0
var enemies_to_spawn: int = 0
var is_wave_active: bool = false
var spawn_timer: float = 0.0

# Resources
const ENEMY_SCENE = preload("res://Scenes/Characters/Enemy.tscn")
const TURRET_SCENE = preload("res://Scenes/Characters/EnemyTurret.tscn")
const TANK_SCENE = preload("res://Scenes/Characters/EnemyTank.tscn")
const BOSS_SCENE = preload("res://Scenes/Characters/EnemyBoss.tscn")
const UPGRADE_SHOP_SCENE = preload("res://Scenes/UI/UpgradeShop.tscn")
const GLOBAL_SHOP_SCENE = preload("res://Scenes/UI/GlobalUpgradeShop.tscn")

@onready var player = get_tree().get_first_node_in_group("player")

# UI Layer
var ui_layer: CanvasLayer

func _ready() -> void:
	# Create a CanvasLayer to hold UI elements like Shop
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Wait for player to be ready
	await get_tree().create_timer(1.0).timeout
	
	# Init HUD (safe to add now as player should be ready)
	# Using load() instead of preload() to prevent cyclic dependency crash
	var hud_scene = load("res://Scenes/UI/HUD.tscn")
	if hud_scene:
		var hud = hud_scene.instantiate()
		ui_layer.add_child(hud)
	
	start_wave(1)

func _process(delta: float) -> void:
	if not is_wave_active: return

	# Spawning Logic
	if enemies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_enemy()
			spawn_timer = spawn_interval

	# Check for Wave Clear
	if enemies_to_spawn <= 0 and get_tree().get_nodes_in_group("enemy").size() == 0:
		end_wave()

func start_wave(wave: int) -> void:
	current_wave = wave
	is_wave_active = true
	
	# Boss Wave Logic (Every 5th wave)
	if wave % 5 == 0:
		# Spawn Boss + Minions
		spawn_boss()
		enemies_to_spawn = 15 + (wave * 2) # Minions to support boss
		print("Wave Manager: BOSS WAVE DETECTED!")
	else:
		enemies_to_spawn = base_enemies_per_wave + (wave * 5)
		
	enemies_remaining = enemies_to_spawn
	
	print("Wave Manager: Starting Wave ", wave, " - Enemies: ", enemies_to_spawn)
	wave_started.emit(wave)

func spawn_boss() -> void:
	var boss = BOSS_SCENE.instantiate()
	get_parent().add_child(boss)
	# Spawn Far Away
	var angle = randf() * TAU
	boss.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * 800.0

func spawn_enemy() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player: return

	var enemy_scene = ENEMY_SCENE
	
	# Normal Waves or Boss Minions
	# Simple weighted spawn logic (can be expanded)
	if current_wave > 2 and randf() < 0.2:
		enemy_scene = TURRET_SCENE
	if current_wave > 4 and randf() < 0.1:
		enemy_scene = TANK_SCENE
		
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	
	# Spawn in circle around player
	var angle = randf() * TAU
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius
	enemy.global_position = spawn_pos
	
	enemies_to_spawn -= 1

func end_wave() -> void:
	print("Wave Manager: Wave ", current_wave, " CLEAR!")
	is_wave_active = false
	wave_completed.emit()
	
	# Trigger Upgrade Phase
	start_upgrade_phase()

func start_upgrade_phase() -> void:
	print("Wave Manager: Upgrade Phase Started")
	upgrade_phase_started.emit()
	
	# Check if we just beat a BOSS (Current wave was multiple of 5)
	if current_wave % 5 == 0:
		# Grant Token
		GameLoop.boss_tokens += 1
		print("Boss Defeated! Tokens: ", GameLoop.boss_tokens)
		
		# Open Global Shop
		var shop = GLOBAL_SHOP_SCENE.instantiate()
		ui_layer.add_child(shop)
		shop.shop_closed.connect(_on_global_shop_closed)
		
	else:
		# Normal Upgrade Shop
		var shop = UPGRADE_SHOP_SCENE.instantiate()
		ui_layer.add_child(shop)
		shop.upgrade_selected.connect(_on_upgrade_selected)

func _on_global_shop_closed() -> void:
	print("Wave Manager: Global Shop Closed. Starting Next Wave.")
	await get_tree().create_timer(1.0).timeout
	start_wave(current_wave + 1)

func _on_upgrade_selected(_upgrade_type) -> void:
	print("Wave Manager: Upgrade Complete. Starting Next Wave.")
	# Start next wave after a short delay
	await get_tree().create_timer(1.0).timeout
	start_wave(current_wave + 1)

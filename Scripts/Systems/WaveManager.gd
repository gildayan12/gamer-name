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
var hud_instance: CanvasLayer

func _ready() -> void:
	# Init HUD directly
	var hud_scene = load("res://Scenes/UI/HUD.tscn")
	if hud_scene:
		print("WaveManager: Spawning HUD...")
		hud_instance = hud_scene.instantiate()
		add_child(hud_instance)
		print("WaveManager: HUD Spawned.")
	else:
		printerr("WaveManager: FAILED TO LOAD HUD SCENE!")
	
	add_to_group("wave_manager")
	start_wave(1)

func debug_skip_to_wave_5_end() -> void:
	print("DEBUG: Skipping to End of Wave 5 (Boss Kill)...")
	current_wave = 5
	
	# Kill all enemies
	get_tree().call_group("enemy", "queue_free")
	get_tree().call_group("boss", "queue_free")
	
	enemies_remaining = 0
	enemies_to_spawn = 0
	is_wave_active = false
	
	# Trigger Wave End logic
	end_wave()

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
	
	# Calculate safe spawn distance (always off-screen)
	var viewport_size = get_viewport().get_visible_rect().size
	# Using length/2 covers the corners. Adding margin.
	var dynamic_radius = max(spawn_radius, (viewport_size.length() / 2.0) + 100.0)
	
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * dynamic_radius
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
		
		# Open Global Shop (Wrap in CanvasLayer)
		var layer = CanvasLayer.new()
		add_child(layer)
		
		var shop = GLOBAL_SHOP_SCENE.instantiate()
		layer.add_child(shop)
		
		# Clean up layer when shop closes
		shop.shop_closed.connect(func(): 
			_on_global_shop_closed()
			layer.queue_free()
		)
		
	else:
		# Normal Upgrade Shop (Wrap in CanvasLayer)
		var layer = CanvasLayer.new()
		add_child(layer)
		
		var shop = UPGRADE_SHOP_SCENE.instantiate()
		layer.add_child(shop)
		
		shop.upgrade_selected.connect(func(type):
			_on_upgrade_selected(type)
			layer.queue_free()
		)

func _on_global_shop_closed() -> void:
	print("Wave Manager: Global Shop Closed. Run Complete!")
	# Trigger Win Report via HUD
	if hud_instance.has_method("show_mission_report"):
		hud_instance.show_mission_report(true) # true = WIN
	else:
		# Fallback if HUD method name differs (it was show_game_over before)
		# Let's add show_mission_report to HUD first or reuse logic
		trigger_victory_fallback()

func trigger_victory_fallback() -> void:
	# Manual instantiation if HUD update pending
	var report = load("res://Scenes/UI/MissionReport.tscn").instantiate()
	hud_instance.add_child(report)
	report.setup(true)
	get_tree().paused = true

func _on_upgrade_selected(_upgrade_type) -> void:
	print("Wave Manager: Upgrade Complete. Starting Next Wave.")
	# Start next wave after a short delay
	await get_tree().create_timer(1.0).timeout
	start_wave(current_wave + 1)

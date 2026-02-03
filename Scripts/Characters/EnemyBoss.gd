extends "res://Scripts/Characters/Enemy.gd"

const BOSS_PROJECTILE_SCENE = preload("res://Scenes/Characters/BossProjectile.tscn")
const MINION_PROJ_SCENE = preload("res://Scenes/Characters/EnemyProjectile.tscn")
const TANK_SCENE = preload("res://Scenes/Characters/EnemyTank.tscn")
const TURRET_SCENE = preload("res://Scenes/Characters/EnemyTurret.tscn")

var teleport_thresholds: Array = [0.75, 0.50, 0.25]
var next_threshold_index: int = 0

var missile_cooldown: float = 8.0 # Slower fire rate (was 5.0)
var current_missile_timer: float = 4.0 # First shot delay

var startup_timer: float = 2.0 # 2s delay before acting


func _ready() -> void:
	add_to_group("boss")
	max_hp = 1000
	hp = max_hp
	is_armored = true # Metal Sound
	speed = 0.0 # Stationary
	drop_chance = 0.0 # Boss logic is separate (Win Token)
	
	# Scale Visuals
	if has_node("Visuals"):
		$Visuals.scale = Vector2(1.5, 1.5)
		$Visuals.modulate = Color(1.0, 0.2, 0.2) # Reddish
	elif has_node("Sprite2D"):
		sprite = $Sprite2D # Fix for Hit Flash
		$Sprite2D.scale = Vector2(1.5, 1.5)
		$Sprite2D.modulate = Color(1.0, 0.2, 0.2)

	super._ready()

		
	# Adjust Health Bar
	if health_bar:
		health_bar.size = Vector2(200, 12)
		health_bar.position = Vector2(-100, -80)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(1.0, 0.8, 0.0, 1.0) # Gold Bar
		health_bar.add_theme_stylebox_override("fill", sb)

func _physics_process(delta: float) -> void:
	if is_frozen: return
	
	if startup_timer > 0:
		startup_timer -= delta
		return
	
	# NO MOVEMENT (Stationary)

	# Chase logic removed/overridden
	
	# Face Player
	if player:
		look_at(player.global_position)
		
	# Attack Logic
	current_missile_timer -= delta
	if current_missile_timer <= 0:
		fire_homing_missile()
		current_missile_timer = missile_cooldown

func fire_homing_missile() -> void:
	var missile = BOSS_PROJECTILE_SCENE.instantiate()
	get_parent().add_child(missile)
	missile.global_position = global_position
	missile.rotation = rotation
	print("BOSS: Fired Homing Missile!")

func take_damage(amount: int, source: String = "gun") -> void:
	super.take_damage(amount, source)
	
	if player and player.has_method("apply_shake"):
		player.apply_shake(3.0) # Impact shake for Boss
		
	check_teleport_threshold()

func check_teleport_threshold() -> void:
	if next_threshold_index >= teleport_thresholds.size():
		return
		
	var threshold_ratio = teleport_thresholds[next_threshold_index]
	var threshold_hp = max_hp * threshold_ratio
	
	if hp <= threshold_hp:
		next_threshold_index += 1
		perform_teleport_phase()

func perform_teleport_phase() -> void:
	print("BOSS: Phase Triggered! Teleporting...")
	
	# 1. Teleport to Random Corner
	var viewport_rect = get_viewport_rect()
	var margin = 200.0
	var corners = [
		Vector2(margin, margin), # Top Left
		Vector2(viewport_rect.size.x - margin, margin), # Top Right
		Vector2(margin, viewport_rect.size.y - margin), # Bottom Left
		Vector2(viewport_rect.size.x - margin, viewport_rect.size.y - margin) # Bottom Right
	]
	
	var chosen_spot = corners.pick_random()
	global_position = chosen_spot
	
	# 2. Summon Minions
	summon_minions()

func summon_minions() -> void:
	print("BOSS: Summoning Minions!")
	
	# Summon 1 Tank and 1 Turret nearby
	var tank = TANK_SCENE.instantiate()
	tank.global_position = global_position + Vector2(150, 0).rotated(randf() * TAU)
	get_parent().call_deferred("add_child", tank)
	
	var turret = TURRET_SCENE.instantiate()
	turret.global_position = global_position + Vector2(150, 0).rotated(randf() * TAU)
	get_parent().call_deferred("add_child", turret)

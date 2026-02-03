extends CharacterBody2D

signal cooldown_updated(type, value_normalized)
signal ultimate_updated(value_percent)
signal ammo_updated(current, max_val)
signal shield_updated(current, max_val)

# ... (Existing vars)

@export var speed: float = 300.0
@export var input_enabled: bool = true # Control flag for Menus/Cutscenes

@onready var visuals: Node2D = $Visuals
@onready var skeleton: Skeleton2D = %Skeleton
@onready var torso_sprite: Sprite2D = $Visuals/Skeleton/Hip/Torso/TorsoSprite
@onready var neck_sprite: Sprite2D = $Visuals/Skeleton/Hip/Torso/Neck/NeckSprite
@onready var head_sprite: Sprite2D = $Visuals/Skeleton/Hip/Torso/Neck/Head/HeadSprite

# Skeletal Sprites (Right Side)
@onready var upper_arm_sprite: Sprite2D = $Visuals/Skeleton/Hip/Torso/UpperArmR/UpperArmSprite
@onready var forearm_sprite: Sprite2D = $Visuals/Skeleton/Hip/Torso/UpperArmR/ForearmR/ForearmSprite
@onready var thigh_sprite: Sprite2D = $Visuals/Skeleton/Hip/ThighR/ThighSprite
@onready var calf_sprite: Sprite2D = $Visuals/Skeleton/Hip/ThighR/CalfR/CalfSprite
@onready var foot_sprite: Sprite2D = $Visuals/Skeleton/Hip/ThighR/CalfR/FootR/FootSprite

# Skeletal Sprites (Left Side)
@onready var upper_arm_l_sprite: Sprite2D = $Visuals/Skeleton/Hip/Torso/UpperArmL/UpperArmSpriteL
@onready var forearm_l_sprite: Sprite2D = $Visuals/Skeleton/Hip/Torso/UpperArmL/ForearmL/ForearmSpriteL
@onready var thigh_l_sprite: Sprite2D = $Visuals/Skeleton/Hip/ThighL/ThighSpriteL
@onready var calf_l_sprite: Sprite2D = $Visuals/Skeleton/Hip/ThighL/CalfL/CalfSpriteL
@onready var foot_l_sprite: Sprite2D = $Visuals/Skeleton/Hip/ThighL/CalfL/FootSpriteL

@onready var aim_root: Node2D = $Visuals/AimRoot
@onready var weapon_group: Node2D = $Visuals/AimRoot/WeaponGroup
# weapon_pivot removed. Use weapon_group instead. 
@onready var weapon_pivot: Node2D = $Visuals/AimRoot/WeaponGroup/WeaponPivot
# --- 8-DIRECTION SYSTEM ---
enum BodyView { FRONT, BACK, SIDE }
var current_body_view: BodyView = BodyView.SIDE
var current_skin_data: Dictionary = {}
@export var current_skin_name: String = "default"
@export var run_speed_scale: float = 1.0

# State for Visuals
var last_facing_dir: int = 1




# Kit System Resources
const GRENADE_SCENE = preload("res://Scenes/Characters/Grenade.tscn")
const BARRETT_SCENE = preload("res://Scenes/Characters/ProjectileBarrett.tscn")
const BAZOOKA_SCENE = preload("res://Scenes/Characters/ProjectileBazooka.tscn")
const PROJECTILE_SCENE = preload("res://Scenes/Characters/Projectile.tscn")
const MAGIC_MISSILE_SCENE = preload("res://Scenes/Characters/MagicMissile.tscn")
const CHAIN_LIGHTNING_SCENE = preload("res://Scenes/Characters/ChainLightning.tscn")
const SHIELD_SHATTER_SCENE = preload("res://Scenes/Characters/ShieldShatterParticles.tscn")
const SHIELD_REGEN_SCENE = preload("res://Scenes/Characters/ShieldRegenParticles.tscn")
const ACID_RAIN_SCENE = preload("res://Scenes/Characters/AcidRainDroplet.tscn")
# New Melee Resources
const SWORD_SCENE = preload("res://Scenes/Characters/Sword.tscn")
const SHOCKWAVE_SCENE = preload("res://Scenes/Characters/Shockwave.tscn")
const BEYBLADE_SCENE = preload("res://Scenes/Characters/Beyblade.tscn")

# Enemy Scenes for Debug Spawning
const ENEMY_SCENE = preload("res://Scenes/Characters/Enemy.tscn")
const TURRET_SCENE = preload("res://Scenes/Characters/EnemyTurret.tscn")
const TANK_SCENE = preload("res://Scenes/Characters/EnemyTank.tscn")
const BOSS_SCENE = preload("res://Scenes/Characters/EnemyBoss.tscn")
const HIT_PARTICLES_SCENE = preload("res://Scenes/Characters/HitParticles.tscn")



enum Kit { GUN, MELEE, MAGE }
var current_kit: Kit = Kit.GUN # Default

enum UltType { NONE, BARRETT, BAZOOKA, BEYBLADE, ROID_RAGE, TIME_FREEZE, PISS_RAIN }
var current_ult: UltType = UltType.BARRETT 

# State
var can_dodge: bool = true
var can_grenade: bool = true
var can_shockwave: bool = true
var ultimate_charge: float = 0.0 
var is_dodging: bool = false
const MAX_THROW_DIST = 400.0 
var max_hp: float = 100.0
var hp: float = 100.0 
var is_spinning: bool = false 
var is_roid_raging: bool = false
var can_chain_lightning: bool = true
# Modifiers
var weapon_damage_modifier: float = 1.0 # Wave Upgrade (Weapon Only)
var global_damage_modifier: float = 1.0 # Global Arena Upgrade (Str)
var ability_damage_modifier: float = 1.0 # Wave Ability Power

var move_speed_modifier: float = 1.0
var attack_speed_modifier: float = 1.0 
var cooldown_modifier: float = 1.0
var dodge_cooldown_modifier: float = 1.0 

# New Utility Modifiers
var magazine_size_modifier: int = 0
var ability_count_modifier: int = 0
var ability_radius_modifier: float = 1.0
var max_shield_modifier: float = 1.0 

# Combat Stats
const FIRE_RATE_SWORD: float = 0.95
const FIRE_RATE_MAGE: float = 0.28  
const FIRE_RATE_GUN: float = 0.2    
const MAX_BLINK_DIST: float = 250.0

# Melee State
var active_sword: Area2D = null
var attack_cooldown: float = 0.0

# Gun State (Ammo)
var max_ammo: int = 8
var current_ammo: int = 8
var is_reloading: bool = false
var is_aiming_grenade: bool = false

# Blink State
var is_aiming_blink: bool = false
var is_aiming_ability: bool = false # For Chain Lightning
var is_aiming_ultimate: bool = false # For Barrett/Bazooka
var time_since_last_shot: float = 0.0
var time_since_ammo_regen: float = 0.0
var charge_audio: AudioStreamPlayer = null # Track the charging loop
var last_shot_audio_time: int = 0 # For Audio Throttling (msec)


# Shield State (Melee)
const MAX_SHIELD_HP: float = 100.0
var shield_hp: float = 100.0
var is_shielding: bool = false
var can_shield: bool = true
var time_since_shield_hit: float = 0.0
var is_shield_broken: bool = false
var shield_active_time: float = 0.0 # Track how long shield is up

# Visual Nodes
var shield_line: Line2D 
var aim_line: Line2D 
var time_freeze_layer: CanvasLayer 
var boss_arrow: Line2D 
var enemy_arrow: Line2D

# Screen Shake
var shake_strength: float = 0.0
var shake_decay: float = 5.0 

func _ready() -> void:
	add_to_group("player")
	
	# Create Shield Visual
	var color_rect = ColorRect.new()
	color_rect.color = Color(0.0, 0.2, 0.8, 0.3) # Blue tint
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	time_freeze_layer = CanvasLayer.new()
	time_freeze_layer.visible = false
	time_freeze_layer.add_child(color_rect)
	add_child(time_freeze_layer)
	
	shield_line = Line2D.new()
	shield_line.width = 5.0
	shield_line.visible = false
	shield_line.visible = false
	add_child(shield_line) 
	
	# Create Boss Arrow (Purple)
	boss_arrow = Line2D.new()
	boss_arrow.width = 15.0
	boss_arrow.default_color = Color(1.0, 0.0, 1.0, 0.7)
	boss_arrow.visible = false
	add_child(boss_arrow)

	# Create Enemy Arrow (Orange)
	enemy_arrow = Line2D.new()
	enemy_arrow.width = 10.0
	enemy_arrow.default_color = Color(1.0, 0.5, 0.0, 0.7)
	enemy_arrow.visible = false
	add_child(enemy_arrow)


	
	# Explicit Collision Setup
	# Layer 1: Environment, Layer 2: Player, Layer 3: Enemy, Layer 4: Enemy Projectile
	# Layer 1: Environment, Layer 2: Player, Layer 3: Enemy, Layer 4: Enemy Projectile
	collision_layer = 2 
	collision_mask = 1 | 4 # World + Enemies

	# Initialize Weapon from GameLoop
	if GameLoop:
		equip_kit(GameLoop.selected_kit as Kit)
	else:
		equip_kit(current_kit)
		
	apply_global_stats()
	
	# Load the default skin (8-direction system)
	load_skin(current_skin_name)

	# FORCE LEFT ARM IK
	# call_deferred("setup_left_arm_ik")

func setup_left_arm_ik() -> void:
	if not skeleton: return
	
	# 1. Ensure we have a target
	var target = skeleton.find_child("LeftHandTarget", true, false)
	if not target:
		print("IK ERROR: LeftHandTarget not found in skeleton!")
		return
		
	print("IK: Found target at ", target.name)
	
	# 2. Get Modification Stack
	var stack = skeleton.get_modification_stack()
	if not stack:
		stack = SkeletonModificationStack2D.new()
		skeleton.set_modification_stack(stack)
		
	# 3. Setup TwoBoneIK
	# Check if we already have one, or make new
	var mod_count = stack.get_modification_count()
	var ik_mod: SkeletonModification2DTwoBoneIK = null
	
	if mod_count > 0:
		var existing = stack.get_modification(0)
		if existing is SkeletonModification2DTwoBoneIK:
			ik_mod = existing
	
	if not ik_mod:
		ik_mod = SkeletonModification2DTwoBoneIK.new()
		stack.add_modification(ik_mod)
		
	# 4. Configure Bones (Use NodePaths relative to Skeleton)
	# Bone Indices usually: 7=UpperArmL, 8=ForearmL (Check your import if different, but usually stable)
	# Easier to set by Name if possible, but Resource uses paths/indices.
	
	# Let's trust the current scene setup or set explicitly
	var upper_node = skeleton.find_child("UpperArmL", true, false)
	var lower_node = skeleton.find_child("ForearmL", true, false)
	
	if not upper_node or not lower_node: 
		print("IK ERROR: Left Arm Bones not found!")
		return

	ik_mod.target_nodepath = skeleton.get_path_to(target)
	ik_mod.set_joint_one_bone2d_node(skeleton.get_path_to(upper_node))
	ik_mod.set_joint_two_bone2d_node(skeleton.get_path_to(lower_node))
	
	stack.enabled = true
	ik_mod.enabled = true
	
	# Force an update
	skeleton.execute_modifications(0.0, 0)
	print("IK: Left Arm IK Force-Enabld via Script")
	
func apply_global_stats() -> void:
	# 1. DMG (Strength)
	var str_bonus = 1.0 + (GameLoop.global_stats["strength"] * 0.1)
	global_damage_modifier = str_bonus

	# 2. SPD (Dexterity) implies Speed, Attack Speed, CDR
	var spd_level = GameLoop.global_stats["dexterity"]
	# NOTE: Move/Attack Speed are calculated dynamically in _process/movement
	
	# CDR from SPD (5% per level)
	var cdr_from_spd = spd_level * 0.05
	cooldown_modifier -= cdr_from_spd
	dodge_cooldown_modifier -= cdr_from_spd # Also reduce Dodge/Shield cooldowns
	
	# Clamp CDR
	cooldown_modifier = max(cooldown_modifier, 0.2)
	dodge_cooldown_modifier = max(dodge_cooldown_modifier, 0.2)

	# 3. Vitality (Intelligence -> Max HP)
	var vit_level = GameLoop.global_stats["intelligence"]
	var hp_bonus = vit_level * 20.0
	
	# Determine Base HP (Use current max if first run, or define constants)
	# Issue: Each call adds to base? No, equation is absolute.
	# But if 'max_hp' was modified by something else?
	# Let's assume standard base 100 for now.
	# Actually, to be safe for TANK kit (if user had one), we need to know base.
	# But player IS the class.
	
	max_hp = 100.0 + hp_bonus 
	hp = max_hp 
	
	# Force HUD Update logic (if signal based)
	# HUD uses _process to read max_hp/hp, but safe to emit if needed
	# No specific signal for "Max HP Changed" in HUD, it reads property directly.
	
	print("Global Stats: DMG x", str_bonus, " SPD x", (1.0 + spd_level * 0.05), " HP: ", max_hp)

func _process(delta: float) -> void:
	if is_aiming_blink or is_aiming_ability or is_aiming_ultimate: # Update for ability aim too
		queue_redraw()
	
	# Boss/Objective Pointer Logic
	update_objective_pointer()
	
	time_since_last_shot += delta

	if is_shielding:
		shield_active_time += delta
		draw_shield_line()
		
		# Auto-drop after 3 seconds
		if shield_active_time >= 3.0:
			drop_shield()
	else:
	# Recharge Shield Logic
		# If not broken and below max (scaled by modifier)
		var max_s = MAX_SHIELD_HP * max_shield_modifier
		if not is_shield_broken and shield_hp < max_s:
			time_since_shield_hit += delta
			if time_since_shield_hit >= 5.0:
				# Regen 20 HP/sec
				shield_hp += 20.0 * delta
				shield_hp = min(shield_hp, max_s)
				shield_updated.emit(shield_hp, max_s)

	# 2. Ammo Regen REMOVED


# ... (Previous code) ...

	# 3. Screen Shake Logic
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		var cam = get_node_or_null("Camera2D")
		if cam:
			cam.offset = Vector2(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)

func apply_shake(strength: float) -> void:
	shake_strength = max(shake_strength, strength)

func _draw() -> void:
	if is_aiming_blink:
		draw_circle(Vector2.ZERO, MAX_BLINK_DIST, Color(0.2, 0.6, 1.0, 0.15))
		draw_arc(Vector2.ZERO, MAX_BLINK_DIST, 0, TAU, 64, Color(0.2, 0.6, 1.0, 0.5), 2.0)
		var mouse_local = get_local_mouse_position()
		var dir = mouse_local.normalized()
		var dist = min(mouse_local.length(), MAX_BLINK_DIST)
		draw_line(Vector2.ZERO, dir * dist, Color(0.2, 0.6, 1.0, 0.5), 2.0)
		
	if is_aiming_ability or is_aiming_ultimate:
		# Draw Aim Line for Grenade / Chain Lightning / Ultimates
		var mouse_local = get_local_mouse_position()
		var dist = mouse_local.length()
		var max_dist = MAX_THROW_DIST if current_kit == Kit.GUN else 600.0
		
		var dir = mouse_local.normalized()
		var draw_dist = min(dist, max_dist)
		
		# Dashed Line or Color diff
		draw_line(Vector2.ZERO, dir * draw_dist, Color(1.0, 0.5, 0.0, 0.6), 2.0) # Orange
		draw_circle(dir * draw_dist, 5.0, Color(1.0, 0.5, 0.0, 0.8))

# ... (Previous code) ...

func throw_grenade() -> void:
	can_grenade = false
	
	# Multicast (Extra Grenades)
	var throw_count = 1 + ability_count_modifier
	var delay_between = 0.1
	
	for i in range(throw_count):
		call_deferred("_spawn_grenade_projectile", i) # Defer to separate spawn logic visually
		if throw_count > 1:
			await get_tree().create_timer(delay_between).timeout
	
	cooldown_updated.emit("shroom", 1.0)
	var tw = create_tween()
	var duration = 5.0 * cooldown_modifier
	tw.tween_method(func(v): cooldown_updated.emit("shroom", v), 1.0, 0.0, duration)
	
	await get_tree().create_timer(duration).timeout
	can_grenade = true

func _spawn_grenade_projectile(index: int) -> void:
	var grenade = GRENADE_SCENE.instantiate()
	get_parent().add_child(grenade)
	grenade.global_position = global_position
	
	var mouse_pos = get_global_mouse_position()
	# Optional spread if multiple
	if index > 0:
		mouse_pos += Vector2(randf_range(-40, 40), randf_range(-40, 40))
		
	var dist = global_position.distance_to(mouse_pos)
	var power_ratio = clamp(dist / MAX_THROW_DIST, 0.2, 1.2)
	
	grenade.direction = (mouse_pos - global_position).normalized()
	grenade.speed = 600.0 * power_ratio
	
	# Apply Global Damage & Shooter (Ability Only)
	grenade.damage = int(50 * ability_damage_modifier * global_damage_modifier)
	grenade.shooter_player = self
	
	# Radius Modifier (Requires Grenade script support? Or scale?)
	# Simple scale for visual and collision:
	grenade.scale = Vector2.ONE * ability_radius_modifier

func update_objective_pointer() -> void:
	# 1. BOSS ARROW
	var boss = get_tree().get_first_node_in_group("boss")
	if boss:
		update_arrow(boss_arrow, boss.global_position)
	else:
		boss_arrow.visible = false

	# 2. ENEMY ARROW (Only if low count)
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0 and enemies.size() <= 5:
		var nearest_dist = INF
		var nearest_enemy = null
		
		for enemy in enemies:
			var d = global_position.distance_to(enemy.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest_enemy = enemy
		
		if nearest_enemy:
			update_arrow(enemy_arrow, nearest_enemy.global_position)
		else:
			enemy_arrow.visible = false
	else:
		enemy_arrow.visible = false

func update_arrow(arrow: Line2D, target_pos: Vector2) -> void:
	var to_target = target_pos - global_position
	# var dist = to_target.length() # Unused
	
	# Only show if off-screen (accounting for aspect ratio and zoom)
	var viewport_size = get_viewport_rect().size
	var zoom = Vector2.ONE
	
	var cam = get_node_or_null("Camera2D")
	if cam:
		zoom = cam.zoom
		
	var half_size = (viewport_size / zoom) / 2.0
	
	# Check if within viewport bounds (with slight margin)
	var is_on_screen = abs(to_target.x) < half_size.x and abs(to_target.y) < half_size.y
	
	if not is_on_screen:
		arrow.visible = true
		arrow.clear_points()
		
		# Draw at fixed distance
		var dir = to_target.normalized()
		var start = dir * 100.0
		var end = dir * 200.0
		
		arrow.add_point(start)
		arrow.add_point(end)
		
		# Arrowhead
		var angle = dir.angle()
		var head_len = 30.0
		var arrow_p1 = end - Vector2(head_len, head_len).rotated(angle + PI/4)
		var arrow_p2 = end - Vector2(head_len, -head_len).rotated(angle - PI/4)
		
		arrow.add_point(arrow_p1)
		arrow.add_point(end)
		arrow.add_point(arrow_p2)
		
	else:
		arrow.visible = false

func draw_shield_line() -> void:
	shield_line.visible = true
	shield_line.clear_points()
	
	var color = Color(0.3, 0.8, 1.0, 0.8) # Cyan
	if shield_hp < 50.0:
		color = color.lerp(Color(1.0, 0.0, 0.0, 0.8), 1.0 - (shield_hp / 50.0))
	shield_line.default_color = color
	
	var center = Vector2.ZERO # Local to player
	var angle_center = get_local_mouse_position().angle()
	var radius = 80.0 # Slightly larger
	var arc_len = PI * 0.8 # ~144 degrees
	var segments = 16
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = (angle_center - arc_len/2.0) + (t * arc_len)
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		shield_line.add_point(point)





func movement() -> void:
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Slow down if shielding
	var current_speed = speed * move_speed_modifier # Applied Wave Speed Modifier
	
	# Global Dex Bonus
	current_speed *= (1.0 + (GameLoop.global_stats["dexterity"] * 0.05))
	
	if is_shielding:
		current_speed *= 0.5
	if is_spinning:
		current_speed *= 0.95
	if is_roid_raging:
		current_speed *= 1.8
		
	velocity = input_vector * current_speed









# Skin Tones and Clothing - REMOVED

func equip_kit(kit: Kit) -> void:
	current_kit = kit
	# Clear old weapons
	for child in weapon_group.get_children():
		child.queue_free()
	
	active_sword = null
	is_reloading = false 
	
	match kit:
		Kit.GUN:
			print("Equipped Gun")
			current_ult = UltType.BARRETT # Default Gun Ult
			ammo_updated.emit(current_ammo, max_ammo) # Force UI
		Kit.MELEE:
			var sword = SWORD_SCENE.instantiate()
			weapon_group.add_child(sword)
			active_sword = sword
			print("Equipped Sword")
			current_ult = UltType.BEYBLADE # Default Melee Ult
			shield_updated.emit(shield_hp, MAX_SHIELD_HP * max_shield_modifier) # Force UI
		Kit.MAGE:
			print("Equipped Mage Staff")
			current_ult = UltType.TIME_FREEZE # Default Mage Ult

func update_hud_stats() -> void:
	# Called by HUD when it connects visuals
	match current_kit:
		Kit.GUN:
			ammo_updated.emit(current_ammo, max_ammo)
		Kit.MELEE:
			shield_updated.emit(shield_hp, MAX_SHIELD_HP * max_shield_modifier)


func _physics_process(delta: float) -> void:
	if not input_enabled: return 

	# Cooldown Management
	if attack_cooldown > 0:
		attack_cooldown -= delta

	# Auto-Fire Input
	if Input.is_action_pressed("attack"):
		try_attack()

	if is_dodging:
		move_and_slide() 
	else:
		movement()
		update_visuals(delta)
		move_and_slide()

# --- PROCEDURAL ANIMATION SYSTEM REMOVED ---



func update_visuals(_delta: float) -> void:
	# --- 8-DIRECTION SYSTEM ---
	var mouse_pos = get_global_mouse_position()
	var aim_dir = (mouse_pos - global_position).normalized()
	var aim_angle = aim_dir.angle()  # -PI to PI
	var aim_deg = rad_to_deg(aim_angle)
	
	# 1. DETERMINE BODY VIEW (Front/Back/Side)
	var new_view = get_body_view_from_aim(aim_deg)
	
	if new_view != current_body_view:
		current_body_view = new_view
		apply_skin_view(new_view)
	
	# 2. FLIP CHARACTER VISUALS
	if visuals:
		if aim_dir.x < 0:
			visuals.scale.x = -abs(visuals.scale.x)
		else:
			visuals.scale.x = abs(visuals.scale.x)
	
	# 3. ROTATE AIM ROOT
	if aim_root:
		aim_root.look_at(mouse_pos)
	
	# 4. LAYER SWAPPING (Weapon Behind/Front)
	if weapon_group:
		if aim_dir.y < -0.20:  # Looking UP
			weapon_group.z_index = -1
		elif aim_dir.y > 0.20:  # Looking DOWN
			weapon_group.z_index = 0
	
	# 5. LEG ANIMATION - SKELETAL (TODO: implement procedural walk)
	# Note: legs_sprite is now Node2D container, not AnimatedSprite2D
	# Skeletal walk animation will be driven by the Skeleton2D bones
	pass

## Determine which body view to use based on aim angle (degrees)
## Determine which body view to use based on aim angle (degrees)
func get_body_view_from_aim(_deg: float) -> BodyView:
	return BodyView.SIDE # Always Side View for this system

## Apply textures for the current view from loaded skin
func apply_skin_view(view: BodyView) -> void:
	if current_skin_data.is_empty():
		return
	
	# Mapping key is always "side" since we simplified the dict
	var textures = current_skin_data.get("side", {})
	
	if textures.is_empty(): return
	
	# Apply to all sprite slots
	if torso_sprite: torso_sprite.texture = textures.get("torso")
	if neck_sprite: neck_sprite.texture = textures.get("neck")
	if head_sprite: head_sprite.texture = textures.get("head")
	
	# Helper to apply texture if node exists
	var apply = func(node: Sprite2D, key: String):
		if node and textures.get(key):
			node.texture = textures[key]
			
	apply.call(upper_arm_sprite, "upper_arm")
	apply.call(forearm_sprite, "forearm")
	apply.call(thigh_sprite, "thigh")
	apply.call(calf_sprite, "calf")
	apply.call(foot_sprite, "foot")
	
	# Apply to Left (Back) side
	apply.call(upper_arm_l_sprite, "upper_arm")
	apply.call(forearm_l_sprite, "forearm")
	apply.call(thigh_l_sprite, "thigh")
	apply.call(calf_l_sprite, "calf")
	apply.call(foot_l_sprite, "foot")

## Load and apply a skin by name
func load_skin(skin_name: String) -> void:
	current_skin_name = skin_name
	current_skin_data = SkinManager.load_skin(skin_name)
	apply_skin_view(current_body_view)

# Input for Manual Reload and Single Clicks
func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled: return 

	# Reload Input
	if event.is_action_pressed("reload"):
		start_reload()

	# Manual Click Handling
	if event.is_action_pressed("attack"): 
		try_attack()
	
	# Abilities
	if event.is_action_pressed("dodge"):
		if can_dodge:
			if current_kit == Kit.MAGE:
				is_aiming_blink = true
			elif current_kit == Kit.MELEE:
				if not is_shield_broken and can_shield:
					is_shielding = true
					print("Shield Up")
			else:
				perform_dodge() # Gun/Melee Roll (Immediate)

	if event.is_action_released("dodge"):
		if is_aiming_blink:
			is_aiming_blink = false
			queue_redraw()
			perform_blink()
		if current_kit == Kit.MELEE and is_shielding:
			drop_shield()
		
	# Cancel Ability / Ultimate (Right Click)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if is_aiming_ability:
			is_aiming_ability = false
			queue_redraw()
			# Audio Feedback
			if current_kit == Kit.GUN:
				AudioManager.play_sfx("grenade_safety")
				print("Grenade Canceled")
			# Stop looping audio
			if charge_audio:
				charge_audio.stop()
				charge_audio = null
			return

		if is_aiming_ultimate:
			is_aiming_ultimate = false
			queue_redraw()
			# "Fast" gun switch off (Pitch shifted up for quick cancel, slightly quieter)
			AudioManager.play_sfx("gun_switch_off", 1.2, -4.0) 
			print("Ultimate Canceled")
			return

	if event.is_action_pressed("ability"):
		if current_kit == Kit.GUN and can_grenade:
			is_aiming_ability = true # Reuse for Grenade too
			AudioManager.play_sfx("grenade_pin") # Pin Pull
		elif current_kit == Kit.MELEE and can_shockwave:
			perform_shockwave()
		elif current_kit == Kit.MAGE and can_chain_lightning:
			is_aiming_ability = true
			# Start Charge Audio
			if charge_audio: charge_audio.stop()
			charge_audio = AudioManager.play_sfx_loop("lightning_charge", 5.0, 1.0, -15.0) # 5s max hold, -15dB quiet
			
	if event.is_action_released("ability"):
		if is_aiming_ability:
			is_aiming_ability = false
			queue_redraw() # Clear Aim Lines
			
			# Stop Charge Audio
			if charge_audio:
				charge_audio.stop()
				charge_audio = null
			
			if current_kit == Kit.GUN:
				AudioManager.play_sfx("grenade_throw")
				# Spoon "ping" just after throw
				get_tree().create_timer(0.05).timeout.connect(func(): AudioManager.play_sfx("grenade_spoon"))
				throw_grenade()
			elif current_kit == Kit.MAGE:
				perform_chain_lightning()
		
	# Ultimate Input Handling (Aim/Fire/Cancel)
	if event.is_action_pressed("ultimate"):
		if ultimate_charge >= 100.0:
			var valid_aim_ult = false
			
			match current_kit:
				Kit.GUN: 
					# Gun Ults (Barrett/Bazooka) need Aiming
					if current_ult == UltType.BARRETT or current_ult == UltType.BAZOOKA:
						is_aiming_ultimate = true
						valid_aim_ult = true
						# GUN SWITCH OFF sound on aim start
						AudioManager.play_sfx("gun_switch_off")
						queue_redraw()
						
				Kit.MELEE:
					if current_ult == UltType.BEYBLADE: perform_beyblade()
					elif current_ult == UltType.ROID_RAGE: perform_roid_rage()
				Kit.MAGE:
					if current_ult == UltType.TIME_FREEZE: perform_time_freeze()
					elif current_ult == UltType.PISS_RAIN: perform_piss_rain()
			
			if not valid_aim_ult:
				# Instant cast ults handled in switch
				pass

	if event.is_action_released("ultimate"):
		if is_aiming_ultimate:
			is_aiming_ultimate = false
			queue_redraw()
			fire_ultimate()


	# DEBUG: Simulate Damage with 'K'
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		take_damage(20, global_position + Vector2(100, 0)) # Hit from right

	# DEBUG: Kit Switching
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: equip_kit(Kit.GUN)
		if event.keycode == KEY_2: equip_kit(Kit.MELEE)
		if event.keycode == KEY_3: equip_kit(Kit.MAGE)
		
		# Spawning Enemies
		if event.keycode == KEY_4: spawn_debug_enemy(ENEMY_SCENE)
		if event.keycode == KEY_5: spawn_debug_enemy(TURRET_SCENE)
		if event.keycode == KEY_7: spawn_debug_enemy(BOSS_SCENE)
		if event.keycode == KEY_8: start_boss_encounter()
		
		# DEBUG: Grant Boss Token
		if event.keycode == KEY_M:
			GameLoop.boss_tokens += 5
			print("DEBUG: Added 5 Boss Tokens. Total: ", GameLoop.boss_tokens)
			# Refresh stats just in case
			apply_global_stats()
			print("Current Stats: ", GameLoop.global_stats)

		if event.keycode == KEY_P:
			# Toggle "Machine Gun Mode"
			if attack_speed_modifier < 5.0:
				attack_speed_modifier = 10.0 # Insane speed 10x
				print("DEBUG: Machine Gun Mode ON (10x Speed)")
			else:
				attack_speed_modifier = 1.0
				print("DEBUG: Machine Gun Mode OFF")

		if event.keycode == KEY_O:
			# Toggle "Rapid Fire Mode"
			if attack_speed_modifier < 2.0:
				attack_speed_modifier = 5.0 # Fast speed 5x
				print("DEBUG: Rapid Fire Mode ON (5x Speed)")
			else:
				attack_speed_modifier = 1.0
				print("DEBUG: Rapid Fire Mode OFF")


		
		if event.keycode == KEY_0:

			# Toggle Ult based on Kit
			if current_kit == Kit.GUN:
				if current_ult == UltType.BARRETT:
					current_ult = UltType.BAZOOKA
					print("Switched to BAZOOKA")
				else:
					current_ult = UltType.BARRETT
					print("Switched to BARRETT")
			
			elif current_kit == Kit.MELEE:
				if current_ult == UltType.BEYBLADE:
					current_ult = UltType.ROID_RAGE
					print("Switched to ROID RAGE")
				else:
					current_ult = UltType.BEYBLADE
					print("Switched to BEYBLADE")
			
			elif current_kit == Kit.MAGE:
				if current_ult == UltType.TIME_FREEZE:
					current_ult = UltType.PISS_RAIN
					print("Switched to PISS RAIN")
				else:
					current_ult = UltType.TIME_FREEZE
					print("Switched to TIME FREEZE")
					
			ultimate_charge = 100.0
			ultimate_updated.emit(100.0)

func try_attack() -> void:
	if attack_cooldown > 0 or is_reloading: return

	match current_kit:
		Kit.GUN:
			shoot_gun()
		Kit.MELEE:
			swing_sword()
		Kit.MAGE:
			shoot_magic()

func start_reload() -> void:
	if is_reloading: return
	if current_kit != Kit.GUN: return
	
	var effective_max = max_ammo + magazine_size_modifier
	if current_ammo >= effective_max: 
		print("Ammo full already")
		return # Full already
	
	print("Reloading...")
	is_reloading = true
	# Immediate feedback
	ammo_updated.emit(current_ammo, effective_max)
	
	# Reload Timer (1.0s)
	await get_tree().create_timer(1.0).timeout
	
	current_ammo = effective_max
	is_reloading = false
	ammo_updated.emit(current_ammo, effective_max)
	print("Reload Complete. Ammo: ", current_ammo)

func shoot_gun() -> void:
	if current_ammo <= 0:
		start_reload()
		return

	if weapon_group:
		current_ammo -= 1
		var effective_max = max_ammo + magazine_size_modifier
		ammo_updated.emit(current_ammo, effective_max)
		# Audio Throttling Logic
		var current_time = Time.get_ticks_msec()
		
		# Define Audio Cap (5x Speed)
		# Base rate is 0.2s (5 shots/sec). 5x speed = 25 shots/sec = 40ms interval.
		var audio_min_interval = 40 # ms
		
		# Calculate Current Speed Multiplier
		var dex_mod = (1.0 + (GameLoop.global_stats["dexterity"] * 0.05))
		var total_speed_mult = attack_speed_modifier * dex_mod
		
		# Volume Reduction: -10.0 db base
		var base_vol = -10.0
		
		if total_speed_mult <= 5.0:
			# Normal Playback
			AudioManager.play_sfx("shoot", 1.0, base_vol, 0.04)
			last_shot_audio_time = current_time
		else:
			# Throttled Playback (Speed > 5x)
			if current_time - last_shot_audio_time >= audio_min_interval:
				# Calculate Pitch Boost based on excess speed
				var excess_speed = total_speed_mult - 5.0
				var pitch_boost = 1.0 + (excess_speed * 0.03)
				
				AudioManager.play_sfx("shoot", pitch_boost, base_vol, 0.04)
				last_shot_audio_time = current_time
		
		# Reset Timer
		time_since_last_shot = 0.0
		
		var projectile = PROJECTILE_SCENE.instantiate()
		get_parent().add_child(projectile)
		
		# Use the Right Hand as the spawn point if possible, otherwise weapon_group
		var spawn_pos = weapon_group.global_position
		var spawn_rot = weapon_group.global_rotation
		
		# Optional: Try to spawn from the actual hand/gun tip if finding the node
		# But sticking to weapon_group for stability for now.
		projectile.global_position = spawn_pos
		projectile.global_rotation = spawn_rot
		
		# Apply Damage: Base * WeaponMod * GlobalMod
		var total_dmg = 10.0 * weapon_damage_modifier * global_damage_modifier
		projectile.damage = int(total_dmg)
		projectile.shooter_player = self
		
		# Attack Speed: Base * WeaponSpeedMod (Wave) * GlobalSpeedMod (Dex)
		# NOTE: dex_mod and total_speed_mult (total_atk_speed) calculated above in Audio Throttling Logic
		
		attack_cooldown = FIRE_RATE_GUN / total_speed_mult
		
		if current_ammo <= 0:
			start_reload()
			
# Skins






			
func add_ultimate_charge(amount: float) -> void:
	if current_ult == UltType.NONE: return
	
	ultimate_charge = min(ultimate_charge + amount, 100.0)
	ultimate_updated.emit(ultimate_charge)
	
	if ultimate_charge >= 100.0:
		# Optional: Play "Ult Ready" sound or visual flash
		pass

func shoot_magic() -> void:
	if weapon_group:
		var missile = MAGIC_MISSILE_SCENE.instantiate()
		get_parent().add_child(missile)
		missile.global_position = weapon_group.global_position
		missile.global_rotation = weapon_group.global_rotation
		missile.shooter_player = self 
		
		# Apply Damage: Base * WeaponMod * GlobalMod (Mage Shot is Primary Weapon)
		var total_dmg = 15.0 * weapon_damage_modifier * global_damage_modifier
		missile.damage = int(total_dmg)
		
		# Attack Speed
		var dex_mod = (1.0 + (GameLoop.global_stats["dexterity"] * 0.05))
		attack_cooldown = FIRE_RATE_MAGE / (attack_speed_modifier * dex_mod)
		
		print("Magic Missile Fired! Dmg: ", missile.damage)
		AudioManager.play_sfx("shoot_magic", 1.0, 10.0, 0.15) # 15% Pitch + 10dB Boost

const SLASH_SCENE = preload("res://Scenes/Characters/SlashProjectile.tscn")



func swing_sword() -> void:
	var slash = SLASH_SCENE.instantiate()
	get_parent().add_child(slash)
	slash.global_position = weapon_group.global_position
	slash.global_rotation = weapon_group.global_rotation
	
	# Attack Speed
	var dex_mod = (1.0 + (GameLoop.global_stats["dexterity"] * 0.05))
	attack_cooldown = FIRE_RATE_SWORD / (attack_speed_modifier * dex_mod)
	
	# Apply Modifiers
	var total_dmg = 40.0 * weapon_damage_modifier * global_damage_modifier
	slash.damage = int(total_dmg)
	
	# Scale slash with damage buff slightly, but respect visual limits
	# Let's use weapon_damage_modifier as visual scale factor
	var visual_scale = max(1.0, weapon_damage_modifier)
	slash.scale = Vector2(1.0, 1.0) * visual_scale
	
	slash.shooter_player = self
	
	if active_sword and active_sword.has_method("swing"):
		active_sword.swing()
		
	print("Slash Fired! Dmg: ", slash.damage)

func perform_dodge() -> void:
	can_dodge = false
	is_dodging = true
	# Pitch Shift: ±6% (range 4-8%)
	AudioManager.play_sfx("player_dash", 1.0, 0.0, 0.06)
	
	# Visual Feedback (Ghost effect)
	modulate.a = 0.5
	
	# Phasing: Disable collision layer AND mask for Enemies and Projectiles
	set_collision_mask_value(3, false) # Ignore Enemy Bodies
	set_collision_mask_value(4, false) # Ignore Enemy Projectiles
	set_collision_layer_value(2, false) # Don't be hit by things checking for Player


	
	# Dash Physics
	var dash_dir = velocity.normalized()
	if dash_dir == Vector2.ZERO:
		dash_dir = (get_global_mouse_position() - global_position).normalized()
	
	velocity = dash_dir * (speed * 2.5)
	
	# Cooldown UI
	cooldown_updated.emit("dodge", 1.0)
	var tw = create_tween()
	var duration = 1.5 * dodge_cooldown_modifier
	tw.tween_method(func(v): cooldown_updated.emit("dodge", v), 1.0, 0.0, duration)
	
	await get_tree().create_timer(0.3).timeout # Dash duration
	
	is_dodging = false
	velocity = Vector2.ZERO
	modulate.a = 1.0
	
	# Re-enable Collision
	set_collision_mask_value(3, true)
	set_collision_mask_value(4, true)
	set_collision_layer_value(2, true)


	
	# Unstuck Logic
	check_dodge_unstuck()
	
	await get_tree().create_timer(max(0.0, duration - 0.3)).timeout
	can_dodge = true

func check_dodge_unstuck() -> void:
	# Check if we ended up inside an enemy or projectile
	var params = PhysicsPointQueryParameters2D.new()
	params.position = global_position
	params.collision_mask = 4 | 8 # Layer 3 (Enemy) and Layer 4 (Enemy Projectile)
	params.collide_with_bodies = true
	params.collide_with_areas = true # Projectiles are often areas
	
	var results = get_world_2d().direct_space_state.intersect_point(params)
	if results.size() > 0:
		var collider = results[0].collider
		print("Dodge ended inside hazard/enemy! Taking damage.")
		take_damage(10, collider.global_position)
		
		# Push out
		var push_dir = (global_position - collider.global_position).normalized()
		if push_dir == Vector2.ZERO: push_dir = Vector2.UP # Fallback
		global_position += push_dir * 60.0 # Teleport out 



func perform_blink() -> void:
	can_dodge = false 
	
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position)
	var dist = dir.length()
	
	if dist > MAX_BLINK_DIST:
		dir = dir.normalized() * MAX_BLINK_DIST
		global_position += dir
	else:
		global_position = mouse_pos
		
	print("Blink!")
	# Pitch Shift: ±3% (range 2-4%)
	AudioManager.play_sfx("teleport", 1.0, 0.0, 0.03)
	
	cooldown_updated.emit("dodge", 1.0)
	var tw = create_tween()
	var duration = 1.5 * dodge_cooldown_modifier
	tw.tween_method(func(v): cooldown_updated.emit("dodge", v), 1.0, 0.0, duration) 
	
	await get_tree().create_timer(duration).timeout
	can_dodge = true



func perform_shockwave() -> void:
	can_shockwave = false
	var wave = SHOCKWAVE_SCENE.instantiate()
	add_child(wave)
	wave.position = Vector2.ZERO
	
	# Apply Stats
	# Apply Stats
	wave.damage = int(25 * ability_damage_modifier * global_damage_modifier) # Ability Only
	wave.shooter_player = self
	
	# Radius Modifier
	wave.scale = Vector2.ONE * ability_radius_modifier
	
	print("Shockwave!")
	
	# Cooldown (Using 'shroom' bar for now as requested)
	cooldown_updated.emit("shroom", 1.0)
	var tw = create_tween()
	var duration = 5.0 * cooldown_modifier
	tw.tween_method(func(v): cooldown_updated.emit("shroom", v), 1.0, 0.0, duration)
	
	await get_tree().create_timer(duration).timeout
	can_shockwave = true

func perform_chain_lightning() -> void:
	can_chain_lightning = false
	
	# Play Cast Sound (Always plays)
	AudioManager.play_sfx("lightning_cast")
	
	# Raycast Logic (Hitscan)
	var space_state = get_world_2d().direct_space_state
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	var max_range = 600.0
	
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + dir * max_range)
	query.collision_mask = 4 # Layer 3 (Enemy)
	query.collide_with_areas = true 

	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	# Instantiate Manager
	var chain_manager = CHAIN_LIGHTNING_SCENE.instantiate()
	get_parent().add_child(chain_manager)
	
	# Configure Manager
	chain_manager.damage = int(35 * ability_damage_modifier * global_damage_modifier)
	chain_manager.max_bounces = 4 + ability_count_modifier # Extra Bounces
	chain_manager.shooter_player = self
	
	if result and result.collider.is_in_group("enemy"):
		# Hit Enemy
		print("Hitscan: Hit Enemy!")
		chain_manager.setup(weapon_group.global_position, result.collider)
		# NOTE: Ultimate Charge is now handled by chain_manager per-hit!
	else:
		# Whiff / Hit Wall
		print("Hitscan: Miss/Wall")
		var end_pos = result.position if result else (global_position + dir * max_range)
		chain_manager.create_lightning_arc(weapon_group.global_position, end_pos)
		
		# Manually trigger cleanup for whiff
		await get_tree().create_timer(0.3).timeout
		chain_manager.queue_free()
	
	print("Chain Lightning Fired!")
	
	# Cooldown
	cooldown_updated.emit("shroom", 1.0)
	var tw = create_tween()
	var duration = 4.0 * cooldown_modifier
	tw.tween_method(func(v): cooldown_updated.emit("shroom", v), 1.0, 0.0, duration)
	
	await get_tree().create_timer(duration).timeout
	can_chain_lightning = true

func perform_time_freeze() -> void:
	ultimate_charge = 0.0
	ultimate_updated.emit(ultimate_charge)
	
	print("ZA WARUDO! Time Stopped.")
	if GameLoop: GameLoop.is_time_frozen = true
	
	# 1. Freeze Enemies & Projectiles
	get_tree().call_group("enemy", "freeze")
	get_tree().call_group("enemy_projectile", "freeze")
	
	# 2. Visuals
	time_freeze_layer.visible = true
	
	# 4. Wait
	await get_tree().create_timer(5.0).timeout
	
	# 5. Resume
	if GameLoop: GameLoop.is_time_frozen = false
	get_tree().call_group("enemy", "unfreeze")
	get_tree().call_group("enemy_projectile", "unfreeze")

	time_freeze_layer.visible = false
	print("Time Resumed.")

func perform_piss_rain() -> void:
	ultimate_charge = 0.0
	ultimate_updated.emit(ultimate_charge)
	
	print("ACID RAIN INCOMING!")
	
	# Rain for 6 seconds
	var duration = 6.0
	
	# Start Audio Loop (Rain/Thunder Atmosphere)
	var audio_player = AudioManager.play_sfx_loop("ult_acid_rain_loop", duration)
	
	var spawn_rate = 0.05 # Fast rain
	var end_time = Time.get_ticks_msec() + (duration * 1000)
	
	while Time.get_ticks_msec() < end_time:
		spawn_acid_rain_droplet()
		await get_tree().create_timer(spawn_rate).timeout
		
	# Stop Loop cleanly
	if audio_player:
		var tw = create_tween()
		tw.tween_property(audio_player, "volume_db", -80.0, 0.5) 
		tw.tween_callback(audio_player.stop)

func spawn_acid_rain_droplet() -> void:
	var drop = ACID_RAIN_SCENE.instantiate()
	get_parent().add_child(drop)
	
	# Spawn across the entire screen width (relative to camera/player)
	var viewport_rect = get_viewport_rect()
	var screen_half_width = viewport_rect.size.x / 2.0
	
	# Add a margin so it covers edges too
	var random_x = global_position.x + randf_range(-screen_half_width * 1.2, screen_half_width * 1.2)
	var start_y = global_position.y - (viewport_rect.size.y / 2.0) - 100 # Just above screen top
	
	drop.global_position = Vector2(random_x, start_y)
	
	# Global Damage
	if drop.get("damage"):
		drop.damage = int(drop.damage * ability_damage_modifier * global_damage_modifier)
	drop.shooter_player = self
	
func perform_beyblade() -> void:
	ultimate_charge = 0.0
	ultimate_updated.emit(ultimate_charge)
	
	is_spinning = true
	var beyblade = BEYBLADE_SCENE.instantiate()
	add_child(beyblade)
	beyblade.position = Vector2.ZERO
	
	# Global Damage
	if beyblade.get("damage"):
		beyblade.damage = int(beyblade.damage * ability_damage_modifier * global_damage_modifier)
	beyblade.shooter_player = self
	
	print("BEYBLADE LET IT RIP!")
	
	# buff HP by 30% (Overheal style)
	# We DO NOT raise max_hp, just give bonus current HP
	var bonus_hp = max_hp * 0.3
	hp += bonus_hp
	
	# Visual Feedback (Heal Number)
	spawn_damage_number(int(bonus_hp), Color.GREEN)
	print("Ultimate Buff! Max HP: ", max_hp, " HP: ", hp)
	
	shield_updated.emit(shield_hp, MAX_SHIELD_HP * max_shield_modifier) 
	
	await get_tree().create_timer(4.0).timeout
	
	# End: Clamp HP back to Max if we are still overhealed
	if hp > max_hp:
		hp = max_hp
	
	is_spinning = false
	print("Ultimate Ended. Max HP: ", max_hp, " HP: ", hp)

func perform_roid_rage() -> void:
	ultimate_charge = 0.0
	ultimate_updated.emit(ultimate_charge)
	
	is_roid_raging = true
	
	# Apply Stats (Additive/Multiplicative correctly)
	# Overheal Logic: +50% HP (No Max Increase)
	var bonus_hp = max_hp * 0.5 
	hp += bonus_hp
	
	# Visual Feedback
	spawn_damage_number(int(bonus_hp), Color.GREEN)
	shield_updated.emit(0, 0) # Force HUD update
	
	# Buff existing modifiers
	move_speed_modifier *= 1.8
	weapon_damage_modifier *= 2.0
	attack_speed_modifier *= 1.8
	
	visuals.modulate = Color(2.0, 0.5, 0.5) # Bright Red
	visuals.scale = Vector2(1.5, 1.5)
	
	print("ROID RAGE! HP:", hp, " DMG: x2 SPD: x1.8")
	
	await get_tree().create_timer(8.0).timeout
	
	# Revert Stats
	# Clamp HP if still overhealed
	if hp > max_hp: hp = max_hp
	
	move_speed_modifier /= 1.8
	weapon_damage_modifier /= 2.0
	attack_speed_modifier /= 1.8
	
	visuals.modulate = Color.WHITE
	visuals.scale = Vector2.ONE
	
	is_roid_raging = false
	print("Roid Rage Ended")

func fire_ultimate() -> void:
	ultimate_charge = 0.0
	ultimate_updated.emit(ultimate_charge)
	
	var projectile
	if current_ult == UltType.BARRETT:
		projectile = BARRETT_SCENE.instantiate()
		AudioManager.play_sfx("ult_barrett", 1.0, -2.0)
		print("ULTIMATE: Barrett Fired!")
	elif current_ult == UltType.BAZOOKA:
		projectile = BAZOOKA_SCENE.instantiate()
		AudioManager.play_sfx("ult_bazooka_fire")
		print("ULTIMATE: Bazooka Fired!")
		
	if projectile:
		get_parent().add_child(projectile)
		projectile.global_position = weapon_group.global_position
		projectile.global_rotation = weapon_group.global_rotation
		
		# Apply Global Damage Boost
		if projectile.get("damage"):
			projectile.damage = int(projectile.damage * ability_damage_modifier * global_damage_modifier)
		projectile.shooter_player = self

# Shield Logic
func drop_shield() -> void:
	if not is_shielding: return
	
	is_shielding = false
	can_shield = false
	shield_active_time = 0.0 # Reset duration timer
	shield_line.visible = false # Explicitly hide
	queue_redraw()
	print("Shield Down")
	
	# 1.5s manual cooldown if not broken
	if not is_shield_broken:
		cooldown_updated.emit("dodge", 1.0) # Reuse dodge bar
		var tw = create_tween()
		var duration = 1.5 * dodge_cooldown_modifier
		tw.tween_method(func(v): cooldown_updated.emit("dodge", v), 1.0, 0.0, duration)
		await get_tree().create_timer(duration).timeout
		can_shield = true
		
		# Regen Visual
		var rp = SHIELD_REGEN_SCENE.instantiate()
		add_child(rp)
		rp.position = Vector2.ZERO

func hit_shield(damage: int) -> void:
	time_since_shield_hit = 0.0
	shield_hp -= damage
	print("Shield Hit! HP: ", shield_hp)
	
	shield_updated.emit(shield_hp, MAX_SHIELD_HP * max_shield_modifier)
	
	if shield_hp <= 0:
		shield_hp = 0
		break_shield()

func break_shield() -> void:
	is_shield_broken = true
	drop_shield() # Force drop
	can_shield = false # Override the manual cooldown reset
	
	print("Shield Broken!")
	
	# Visuals
	var p = SHIELD_SHATTER_SCENE.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	apply_shake(5.0)
	
	cooldown_updated.emit("dodge", 1.0)
	var tw = create_tween()
	# 8s Cooldown for broken shield
	var duration = 8.0 * dodge_cooldown_modifier
	tw.tween_method(func(v): cooldown_updated.emit("dodge", v), 1.0, 0.0, duration)
	
	await get_tree().create_timer(duration).timeout
	
	is_shield_broken = false
	shield_hp = MAX_SHIELD_HP * max_shield_modifier # Full restore on return
	can_shield = true
	shield_updated.emit(shield_hp, MAX_SHIELD_HP * max_shield_modifier)
	print("Shield Restored")
	
	# Regen Visual
	var rp = SHIELD_REGEN_SCENE.instantiate()
	add_child(rp)
	rp.position = Vector2.ZERO

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO) -> void:
	# Check for Block
	if is_shielding:
		var mouse_dir = (get_global_mouse_position() - global_position).normalized()
		var hit_dir = (source_pos - global_position).normalized()
		var dot = mouse_dir.dot(hit_dir)
		
		# Debug Prints (Remove later)
		print("DEBUG BLOCK: MouseDir:", mouse_dir, " HitDir:", hit_dir, " Dot:", dot)
		

		# Check angle (dot product > 0.3 means roughly 145 degree cone in front)
		if dot > 0.3:
			# Block Successful
			hit_shield(amount)
			var chip_damage = int(amount * 0.2)
			hp -= chip_damage
			if hp < 0: hp = 0
			print("Blocked! Shield took ", amount, " damage. Player took ", chip_damage, " chip damage. HP: ", hp)
			
			if hp <= 0:
				die()
			
			return # Blocked
			
	# Regular Damage Logic
	if hp <= 0: return # Already dead
	
	apply_shake(5.0) # Medium shake on hurt
	AudioManager.play_sfx("player_hurt")
	
	hp -= amount
	if hp < 0: hp = 0
	
	if GameLoop:
		GameLoop.report_damage_taken(amount)
	
	print("Player took full damage: ", amount, " HP: ", hp)
	
	if hp <= 0:
		die()

func die() -> void:
	if not input_enabled: return # Already dead
	
	print("PLAYER DIED!")
	input_enabled = false
	
	# Stop Physics
	velocity = Vector2.ZERO
	set_physics_process(false)
	
	# Death Animation
	# Death Animation
	var tw = create_tween()
	tw.set_parallel(true)
	
	# 1. Fall Over (Fast)
	tw.tween_property(visuals, "rotation_degrees", 90.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# 2. Bounce Effect (Vertical Jiggle on Impact)
	var bounce_tw = create_tween()
	bounce_tw.tween_interval(0.4) # Wait for fall
	# Bounce Up
	bounce_tw.tween_property(visuals, "position:y", -20.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Land
	bounce_tw.tween_property(visuals, "position:y", 0.0, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	
	# 3. Fade Out (Slower)
	tw.tween_property(visuals, "modulate", Color(1, 0, 0, 0), 1.5).set_delay(0.2) # Fade to red/transparent
	
	# Blood Spatter
	for i in range(3):
		var p = HIT_PARTICLES_SCENE.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		p.modulate = Color(0.8, 0.0, 0.0) # Red particles
		
	await get_tree().create_timer(1.2).timeout
	
	# Show Game Over Screen
	var hud = get_tree().get_first_node_in_group("hud") # Assumes HUD is in group 'hud'
	
	# Fallback: Find HUD manually if group fail
	if not hud:
		hud = get_parent().get_node_or_null("HUD")
		
	if hud and hud.has_method("show_game_over"):
		var waves = 1
		if GameLoop: waves = GameLoop.current_wave
		hud.show_game_over(waves)
	else:
		# Emergency Restart if no HUD
		print("No HUD found for Game Over. Restarting in 3s...")
		await get_tree().create_timer(3.0).timeout
		get_tree().reload_current_scene()

func spawn_debug_enemy(scene: PackedScene) -> void:
	var enemy = scene.instantiate()
	get_parent().add_child(enemy)
	# Spawn near mouse
	enemy.global_position = get_global_mouse_position()
	print("Spawned enemy: ", scene.resource_path)

func start_boss_encounter() -> void:
	print("DEBUG: Starting Boss Encounter Setup")
	
	# 1. Clear existing enemies
	get_tree().call_group("enemy", "queue_free")
	get_tree().call_group("enemy_projectile", "queue_free")
	
	# 2. Position Player (Far Left)
	var viewport = get_viewport_rect().size
	var center_y = viewport.y / 2
	var margin_player = 150.0 # Increased margin
	var margin_boss = 200.0 # Increased margin
	
	global_position = Vector2(margin_player, center_y)
	
	# 3. Spawn Boss (Far Right)
	var boss = BOSS_SCENE.instantiate()
	get_parent().add_child(boss)
	boss.global_position = Vector2(viewport.x - margin_boss, center_y)
	
	# 4. Spawn Turrets (Extreme Corners)
	var t_margin = 60.0 # Pushed further into corners
	var turret_positions = [
		Vector2(t_margin, t_margin), 
		Vector2(viewport.x - t_margin, t_margin), 
		Vector2(t_margin, viewport.y - t_margin), 
		Vector2(viewport.x - t_margin, viewport.y - t_margin) 
	]

	
	# Actually, the user drawing showed:
	# Player Left
	# Boss Right
	# Turrets: Top Left, Bottom Left (behind player?), Top Right, Bottom Right (behind boss?)
	# Let's stick to the drawing interpretation: 4 corners of the play area.
	
	for pos in turret_positions:
		var t = TURRET_SCENE.instantiate()
		get_parent().add_child(t)
		t.global_position = pos
		
	# 5. Spawn Tanks (Flanking Boss)
	var boss_pos = boss.global_position
	# Tank left of boss, Tank right of boss?
	# Drawing showed Green dots flanking the red stickman.
	var tank1 = TANK_SCENE.instantiate()
	get_parent().add_child(tank1)
	tank1.global_position = boss_pos + Vector2(-200, 0) # In front of boss
	
	var tank2 = TANK_SCENE.instantiate() # Maybe behind? Drawing was simplistic. 
	# Let's put one above and one below boss for better gameplay?
	# Drawing looked like:  Tank  BOSS  Tank (Horizontal line?)
	# Let's try flanking left/right for now.
	get_parent().add_child(tank2)
	tank2.global_position = boss_pos + Vector2(200, 0)
func heal(amount: int) -> void:
	hp = min(hp + amount, max_hp)
	spawn_damage_number(amount, Color.GREEN)
	# Force HUD update if needed, but _process handles it
	
func spawn_damage_number(amount: int, color: Color = Color.WHITE) -> void:
	var dn = load("res://Scenes/UI/DamageNumber.tscn").instantiate()
	get_parent().add_child(dn) # Add to same parent as player (Arena)
	dn.global_position = global_position + Vector2(0, -50) # Above head
	
	if dn.has_method("setup"):
		dn.setup(amount) 
		dn.modulate = color 
	else:
		dn.get_node("Label").text = str(amount)
		dn.modulate = color

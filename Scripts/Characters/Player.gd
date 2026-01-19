extends CharacterBody2D

@export var speed: float = 300.0
@export var input_enabled: bool = true # Control flag for Menus/Cutscenes

@onready var visuals: Node2D = $Visuals
@onready var body_sprite: Sprite2D = $Visuals/BodySprite
# Slots
@onready var head_sprite: Sprite2D = $Visuals/HeadSprite
@onready var chest_sprite: Sprite2D = $Visuals/ChestSprite
@onready var legs_sprite: Sprite2D = $Visuals/LegsSprite
@onready var feet_sprite: Sprite2D = $Visuals/FeetSprite

@onready var weapon_pivot: Node2D = $Visuals/WeaponPivot

# Signals for HUD
signal cooldown_updated(type: String, progress: float) 
signal ultimate_updated(value: float)

# Kit System Resources
const GRENADE_SCENE = preload("res://Scenes/Characters/Grenade.tscn")
const BARRETT_SCENE = preload("res://Scenes/Characters/ProjectileBarrett.tscn")
const BAZOOKA_SCENE = preload("res://Scenes/Characters/ProjectileBazooka.tscn")
const PROJECTILE_SCENE = preload("res://Scenes/Characters/Projectile.tscn")
const MAGIC_MISSILE_SCENE = preload("res://Scenes/Characters/MagicMissile.tscn")
const CHAIN_LIGHTNING_SCENE = preload("res://Scenes/Characters/ChainLightning.tscn")
const ACID_RAIN_SCENE = preload("res://Scenes/Characters/AcidRainDroplet.tscn")
# New Melee Resources
const SWORD_SCENE = preload("res://Scenes/Characters/Sword.tscn")
const SHOCKWAVE_SCENE = preload("res://Scenes/Characters/Shockwave.tscn")
const BEYBLADE_SCENE = preload("res://Scenes/Characters/Beyblade.tscn")

# Enemy Scenes for Debug Spawning
const ENEMY_SCENE = preload("res://Scenes/Characters/Enemy.tscn")
const TURRET_SCENE = preload("res://Scenes/Characters/EnemyTurret.tscn")
const TANK_SCENE = preload("res://Scenes/Characters/EnemyTank.tscn")


enum Kit { GUN, MELEE, MAGE }
var current_kit: Kit = Kit.GUN # Default

enum UltType { NONE, BARRETT, BAZOOKA, BEYBLADE, ROID_RAGE, TIME_FREEZE, PISS_RAIN }
var current_ult: UltType = UltType.BARRETT 

# State
var can_dodge: bool = true
var can_grenade: bool = true
var can_shockwave: bool = true
var ultimate_charge: float = 100.0 
var is_dodging: bool = false
const MAX_THROW_DIST = 400.0 
var max_hp: float = 100.0
var hp: float = 100.0 
var is_spinning: bool = false 
var is_roid_raging: bool = false
var can_chain_lightning: bool = true
var damage_modifier: float = 1.0
var speed_modifier: float = 1.0
var attack_speed_modifier: float = 1.0 

# Combat Stats
const FIRE_RATE_SWORD: float = 0.95
const FIRE_RATE_MAGE: float = 0.35  
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
	
	# Create Aim Line (Laser Sight)
	aim_line = Line2D.new()
	aim_line.width = 2.0
	aim_line.default_color = Color(1.0, 0.0, 0.0, 0.4) # Faint red
	add_child(aim_line)
	
	chest_sprite.scale = Vector2(0.8, 0.8)
	
	# Explicit Collision Setup
	# Layer 1: Environment, Layer 2: Player, Layer 3: Enemy, Layer 4: Enemy Projectile
	collision_layer = 2 
	collision_mask = 1 | 4 # World + Enemies


	if has_node("/root/SaveSystem"):
		set_skin_tone(SaveSystem.get_skin_tone())
		var outfit_ids = SaveSystem.get_equipped_items()
		if "chest_hoodie_red" in outfit_ids.values():
			equip_item(load("res://Assets/Items/Chest/HoodieRed.tres"))
		elif "chest_hoodie_blue" in outfit_ids.values():
			equip_item(load("res://Assets/Items/Chest/HoodieBlue.tres"))
	else:
		set_skin_tone(0)

	# Initialize Weapon
	equip_kit(current_kit)

func _process(delta: float) -> void:
	if is_aiming_blink:
		queue_redraw()
	
	if is_shielding:
		shield_active_time += delta
		draw_shield_line()
		
		# Max Duration: 3 Seconds
		if shield_active_time >= 3.0:
			drop_shield()
	else:
		shield_line.visible = false
	
	# Shield Regen Logic
	if not is_shielding and not is_shield_broken:
		time_since_shield_hit += delta
		if time_since_shield_hit > 5.0 and shield_hp < MAX_SHIELD_HP:
			shield_hp += 10.0 * delta # Regen 10 HP/s
			shield_hp = min(shield_hp, MAX_SHIELD_HP)

	# Laser Sight / Aim Arrow Logic
	aim_line.visible = false
	aim_line.clear_points()
	
	if is_aiming_ability:
		if current_kit == Kit.MAGE and can_chain_lightning:
			# Lightning Arrow (Comfort aim)
			var mouse_local = get_local_mouse_position()
			var dist = min(mouse_local.length(), 150.0) # Cap length
			draw_aim_arrow(mouse_local.normalized() * dist, Color(1.0, 0.0, 0.0, 0.4))
			
		elif current_kit == Kit.GUN and can_grenade:
			# Grenade Arrow (Power indicator)
			var mouse_pos = get_global_mouse_position()
			var dist_full = global_position.distance_to(mouse_pos)
			var power_ratio = clamp(dist_full / MAX_THROW_DIST, 0.2, 1.2)
			
			var visual_length = 50.0 + (power_ratio * 100.0) # 70px to 170px
			var dir = (mouse_pos - global_position).normalized()
			
			draw_aim_arrow(dir * visual_length, Color(1.0, 1.0, 0.0, 0.6))

func draw_aim_arrow(end_point_local: Vector2, color: Color) -> void:
	aim_line.visible = true
	aim_line.default_color = color
	aim_line.add_point(weapon_pivot.global_position - global_position) # Start
	aim_line.add_point(end_point_local) # End
	
	# Arrow Head
	var head_len = 10.0
	var angle = end_point_local.angle()
	var arrow_p1 = end_point_local - Vector2(head_len, head_len).rotated(angle + PI/4)
	var arrow_p2 = end_point_local - Vector2(head_len, -head_len).rotated(angle - PI/4)
	
	# We can't easily branch lines in Line2D, so we cheat and re-trace back to tip then other side
	aim_line.add_point(arrow_p1)
	aim_line.add_point(end_point_local)
	aim_line.add_point(arrow_p2)



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

func _draw() -> void:
	if is_aiming_blink:
		draw_circle(Vector2.ZERO, MAX_BLINK_DIST, Color(0.2, 0.6, 1.0, 0.15))
		draw_arc(Vector2.ZERO, MAX_BLINK_DIST, 0, TAU, 64, Color(0.2, 0.6, 1.0, 0.5), 2.0)
		var mouse_local = get_local_mouse_position()
		var dir = mouse_local.normalized()
		var dist = min(mouse_local.length(), MAX_BLINK_DIST)
		draw_line(Vector2.ZERO, dir * dist, Color(0.2, 0.6, 1.0, 0.5), 2.0)



func movement() -> void:
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Slow down if shielding
	var current_speed = speed
	if is_shielding:
		current_speed *= 0.5
	if is_shielding:
		current_speed *= 0.5
	if is_spinning:
		current_speed *= 0.95
	if is_roid_raging:
		current_speed *= 1.8
		
	velocity = input_vector * current_speed









# Skin Tones
const SKIN_COLORS = [
	Color(0.96, 0.80, 0.60), 
	Color(0.80, 0.60, 0.40), 
	Color(0.50, 0.35, 0.20)  
]



func set_skin_tone(index: int) -> void:
	if index >= 0 and index < SKIN_COLORS.size():
		body_sprite.modulate = SKIN_COLORS[index]
		if has_node("/root/SaveSystem"):
			SaveSystem.set_skin_tone(index)

func equip_item(item: ApparelItem) -> void:
	if item == null: return
	
	var target_sprite: Sprite2D
	match item.slot:
		ApparelItem.Slot.HEAD: target_sprite = head_sprite
		ApparelItem.Slot.CHEST: target_sprite = chest_sprite
		ApparelItem.Slot.LEGS: target_sprite = legs_sprite
		ApparelItem.Slot.FEET: target_sprite = feet_sprite
	
	if target_sprite:
		target_sprite.texture = item.texture
		target_sprite.modulate = item.tint
		if has_node("/root/SaveSystem"):
			SaveSystem.equip_item_id(item.slot, item.id)

func equip_kit(kit: Kit) -> void:
	current_kit = kit
	# Clear old weapons
	for child in weapon_pivot.get_children():
		child.queue_free()
	
	active_sword = null
	is_reloading = false 
	
	match kit:
		Kit.GUN:
			print("Equipped Gun")
			current_ult = UltType.BARRETT # Default Gun Ult
		Kit.MELEE:
			var sword = SWORD_SCENE.instantiate()
			weapon_pivot.add_child(sword)
			active_sword = sword
			print("Equipped Sword")
			current_ult = UltType.BEYBLADE # Default Melee Ult
		Kit.MAGE:
			print("Equipped Mage Staff")
			current_ult = UltType.TIME_FREEZE # Default Mage Ult


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
		aiming()
		move_and_slide()



func aiming() -> void:
	var mouse_pos = get_global_mouse_position()
	if weapon_pivot:
		weapon_pivot.look_at(mouse_pos)
	if visuals:
		if mouse_pos.x < global_position.x:
			visuals.scale.x = -1
		else:
			visuals.scale.x = 1

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
		
	if event.is_action_pressed("ability"):
		if current_kit == Kit.GUN and can_grenade:
			is_aiming_ability = true # Reuse for Grenade too
		elif current_kit == Kit.MELEE and can_shockwave:
			perform_shockwave()
		elif current_kit == Kit.MAGE and can_chain_lightning:
			is_aiming_ability = true
			
	if event.is_action_released("ability"):
		if is_aiming_ability:
			is_aiming_ability = false
			if current_kit == Kit.GUN:
				throw_grenade()
			elif current_kit == Kit.MAGE:
				perform_chain_lightning()
		
	if event.is_action_pressed("ultimate"):
		if ultimate_charge >= 100.0:
			# Verify the ultimate matches the kit
			var is_valid = false
			match current_kit:
				Kit.GUN: is_valid = (current_ult == UltType.BARRETT or current_ult == UltType.BAZOOKA)
				Kit.MELEE: is_valid = (current_ult == UltType.BEYBLADE or current_ult == UltType.ROID_RAGE)
				Kit.MAGE: is_valid = (current_ult == UltType.TIME_FREEZE or current_ult == UltType.PISS_RAIN)
			
			if is_valid:
				match current_ult:
					UltType.BARRETT, UltType.BAZOOKA:
						fire_ultimate()
					UltType.BEYBLADE:
						perform_beyblade()
					UltType.ROID_RAGE:
						perform_roid_rage()
					UltType.TIME_FREEZE:
						perform_time_freeze()
					UltType.PISS_RAIN:
						perform_piss_rain()
			else:
				print("Cannot use this ultimate with current kit!")


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
		if event.keycode == KEY_6: spawn_debug_enemy(TANK_SCENE)
		
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
	if current_ammo >= max_ammo: 
		print("Ammo full already")
		return # Full already
	
	print("Reloading...")
	is_reloading = true
	
	# Reload Timer (1.0s)
	await get_tree().create_timer(1.0).timeout
	
	current_ammo = max_ammo
	is_reloading = false
	print("Reload Complete. Ammo: ", current_ammo)

func shoot_gun() -> void:
	if current_ammo <= 0:
		start_reload()
		return

	if weapon_pivot:
		current_ammo -= 1
		print("Bang! Ammo: ", current_ammo)
		
		var projectile = PROJECTILE_SCENE.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = weapon_pivot.global_position
		projectile.global_rotation = weapon_pivot.global_rotation
		
		projectile.global_rotation = weapon_pivot.global_rotation
		
		attack_cooldown = FIRE_RATE_GUN / attack_speed_modifier
		
		if current_ammo <= 0:
			start_reload()
			
		if current_ult != UltType.NONE:
			ultimate_charge = min(ultimate_charge + 5.0, 100.0)
			ultimate_updated.emit(ultimate_charge)

func shoot_magic() -> void:
	if weapon_pivot:
		var missile = MAGIC_MISSILE_SCENE.instantiate()
		get_parent().add_child(missile)
		missile.global_position = weapon_pivot.global_position
		missile.global_rotation = weapon_pivot.global_rotation
		
		missile.global_rotation = weapon_pivot.global_rotation
		
		attack_cooldown = FIRE_RATE_MAGE / attack_speed_modifier
		print("Magic Missile Fired!")

const SLASH_SCENE = preload("res://Scenes/Characters/SlashProjectile.tscn")

func swing_sword() -> void:
	var slash = SLASH_SCENE.instantiate()
	get_parent().add_child(slash)
	slash.global_position = weapon_pivot.global_position
	slash.global_rotation = weapon_pivot.global_rotation
	
	slash.global_rotation = weapon_pivot.global_rotation
	
	attack_cooldown = FIRE_RATE_SWORD / attack_speed_modifier
	
	# Apply Modifiers
	slash.damage = int(40 * damage_modifier)
	slash.scale = Vector2(1.0, 1.0) * (damage_modifier if damage_modifier > 1.0 else 1.0) # Bigger slash if buffed
	
	if active_sword and active_sword.has_method("swing"):
		active_sword.swing()
		
	print("Slash Fired! Dmg: ", slash.damage)

func perform_dodge() -> void:
	can_dodge = false
	is_dodging = true
	
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
	tw.tween_method(func(v): cooldown_updated.emit("dodge", v), 1.0, 0.0, 1.5)
	
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
	
	await get_tree().create_timer(1.2).timeout
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
	
	cooldown_updated.emit("dodge", 1.0)
	var tw = create_tween()
	tw.tween_method(func(v): cooldown_updated.emit("dodge", v), 1.0, 0.0, 1.5) 
	
	await get_tree().create_timer(1.5).timeout
	can_dodge = true

func throw_grenade() -> void:
	can_grenade = false
	var grenade = GRENADE_SCENE.instantiate()
	get_parent().add_child(grenade)
	grenade.global_position = global_position
	
	var mouse_pos = get_global_mouse_position()
	var dist = global_position.distance_to(mouse_pos)
	var power_ratio = clamp(dist / MAX_THROW_DIST, 0.2, 1.2)
	
	grenade.direction = (mouse_pos - global_position).normalized()
	grenade.speed = 600.0 * power_ratio
	
	cooldown_updated.emit("shroom", 1.0)
	var tw = create_tween()
	tw.tween_method(func(v): cooldown_updated.emit("shroom", v), 1.0, 0.0, 5.0)
	
	await get_tree().create_timer(5.0).timeout
	can_grenade = true

func perform_shockwave() -> void:
	can_shockwave = false
	var wave = SHOCKWAVE_SCENE.instantiate()
	add_child(wave)
	wave.position = Vector2.ZERO
	
	print("Shockwave!")
	
	# Cooldown (Using 'shroom' bar for now as requested)
	cooldown_updated.emit("shroom", 1.0)
	var tw = create_tween()
	tw.tween_method(func(v): cooldown_updated.emit("shroom", v), 1.0, 0.0, 5.0)
	
	await get_tree().create_timer(5.0).timeout
	can_shockwave = true

func perform_chain_lightning() -> void:
	can_chain_lightning = false
	
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
	
	if result and result.collider.is_in_group("enemy"):
		# Hit Enemy
		print("Hitscan: Hit Enemy!")
		chain_manager.setup(weapon_pivot.global_position, result.collider)
	else:
		# Whiff / Hit Wall
		print("Hitscan: Miss/Wall")
		var end_pos = result.position if result else (global_position + dir * max_range)
		chain_manager.create_lightning_arc(weapon_pivot.global_position, end_pos)
		# No setup call, so it won't chain, just draws one line then dies.
		# Manually trigger cleanup for whiff
		await get_tree().create_timer(0.3).timeout
		chain_manager.queue_free()
	
	print("Chain Lightning Fired!")
	
	# Cooldown
	cooldown_updated.emit("shroom", 1.0)
	var tw = create_tween()
	tw.tween_method(func(v): cooldown_updated.emit("shroom", v), 1.0, 0.0, 4.0)
	
	await get_tree().create_timer(4.0).timeout
	can_chain_lightning = true

func perform_time_freeze() -> void:
	ultimate_charge = 0.0
	ultimate_updated.emit(ultimate_charge)
	
	print("ZA WARUDO! Time Stopped.")
	
	# 1. Freeze Enemies
	get_tree().call_group("enemy", "freeze")
	
	# 2. Visuals
	time_freeze_layer.visible = true
	
	# 3. Audio (Hypothetical)
	# $Audio.play("time_stop")

	# 4. Wait
	await get_tree().create_timer(5.0).timeout
	
	# 5. Resume
	get_tree().call_group("enemy", "unfreeze")
	time_freeze_layer.visible = false
	print("Time Resumed.")

func perform_piss_rain() -> void:
	ultimate_charge = 0.0
	ultimate_updated.emit(ultimate_charge)
	
	print("ACID RAIN INCOMING!")
	
	# Rain for 6 seconds
	# We can use a simple Loop with delays or a Timer
	var duration = 6.0
	var spawn_rate = 0.05 # Fast rain
	var end_time = Time.get_ticks_msec() + (duration * 1000)
	
	while Time.get_ticks_msec() < end_time:
		spawn_acid_rain_droplet()
		await get_tree().create_timer(spawn_rate).timeout

func spawn_acid_rain_droplet() -> void:
	var drop = ACID_RAIN_SCENE.instantiate()
	get_parent().add_child(drop)
	
	# Spawn randomly around player's X, but high up Y
	var random_x = global_position.x + randf_range(-600, 600)
	var start_y = global_position.y - 500 # Slightly above screen
	
	drop.global_position = Vector2(random_x, start_y)

func perform_beyblade() -> void:
	ultimate_charge = 0.0
	ultimate_updated.emit(ultimate_charge)
	
	is_spinning = true
	var beyblade = BEYBLADE_SCENE.instantiate()
	add_child(beyblade)
	beyblade.position = Vector2.ZERO
	
	print("BEYBLADE LET IT RIP!")
	
	# buff HP by 30%
	var bonus_hp = max_hp * 0.3
	max_hp += bonus_hp
	hp += bonus_hp
	print("Ultimate Buff! Max HP: ", max_hp, " HP: ", hp)
	
	await get_tree().create_timer(4.0).timeout
	
	# Remove buff
	max_hp -= bonus_hp
	if hp > max_hp:
		hp = max_hp
	
	is_spinning = false
	print("Ultimate Ended. Max HP: ", max_hp, " HP: ", hp)

func perform_roid_rage() -> void:
	ultimate_charge = 0.0
	ultimate_updated.emit(ultimate_charge)
	
	is_roid_raging = true
	
	# Apply Stats
	var bonus_hp = max_hp * 0.5 # +50% (Total 1.5x)
	max_hp += bonus_hp
	hp += bonus_hp
	
	speed_modifier = 1.8
	damage_modifier = 2.0
	attack_speed_modifier = 1.8
	visuals.modulate = Color(2.0, 0.5, 0.5) # Bright Red
	visuals.scale = Vector2(1.5, 1.5)
	
	print("ROID RAGE! HP:", hp, " DMG: x2 SPD: x1.8")
	
	await get_tree().create_timer(8.0).timeout
	
	# Revert Stats
	max_hp -= bonus_hp
	if hp > max_hp: hp = max_hp
	
	speed_modifier = 1.0
	damage_modifier = 1.0
	attack_speed_modifier = 1.0
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
		print("ULTIMATE: Barrett Fired!")
	elif current_ult == UltType.BAZOOKA:
		projectile = BAZOOKA_SCENE.instantiate()
		print("ULTIMATE: Bazooka Fired!")
		
	if projectile:
		get_parent().add_child(projectile)
		projectile.global_position = weapon_pivot.global_position
		projectile.global_rotation = weapon_pivot.global_rotation

# Shield Logic
func drop_shield() -> void:
	if not is_shielding: return
	
	is_shielding = false
	can_shield = false
	shield_active_time = 0.0 # Reset duration timer
	queue_redraw()
	print("Shield Down")
	
	# 1.5s manual cooldown if not broken
	if not is_shield_broken:
		cooldown_updated.emit("dodge", 1.0) # Reuse dodge bar
		var tw = create_tween()
		tw.tween_method(func(v): cooldown_updated.emit("dodge", v), 1.0, 0.0, 1.5)
		await get_tree().create_timer(1.5).timeout
		can_shield = true

func hit_shield(damage: int) -> void:
	time_since_shield_hit = 0.0
	shield_hp -= damage
	print("Shield Hit! HP: ", shield_hp)
	
	if shield_hp <= 0:
		shield_hp = 0
		break_shield()

func break_shield() -> void:
	is_shield_broken = true
	drop_shield() # Force drop
	can_shield = false # Override the manual cooldown reset
	
	print("Shield Broken!")
	cooldown_updated.emit("dodge", 1.0)
	var tw = create_tween()
	# 8s Cooldown for broken shield
	tw.tween_method(func(v): cooldown_updated.emit("dodge", v), 1.0, 0.0, 8.0)
	
	await get_tree().create_timer(8.0).timeout
	is_shield_broken = false
	shield_hp = MAX_SHIELD_HP # Full restore on return
	can_shield = true
	print("Shield Restored")

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
			print("Blocked! Shield took ", amount, " damage. Player took ", chip_damage, " chip damage. HP: ", hp)
			return # Blocked
			
	# Regular Damage Logic
	hp -= amount
	print("Player took full damage: ", amount, " HP: ", hp)

func spawn_debug_enemy(scene: PackedScene) -> void:
	var enemy = scene.instantiate()
	get_parent().add_child(enemy)
	# Spawn near mouse
	enemy.global_position = get_global_mouse_position()
	print("Spawned enemy: ", scene.resource_path)

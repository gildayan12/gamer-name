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
# New Melee Resources
const SWORD_SCENE = preload("res://Scenes/Characters/Sword.tscn")

enum Kit { GUN, MELEE, MAGE }
var current_kit: Kit = Kit.GUN # Default

enum UltType { NONE, BARRETT, BAZOOKA }
var current_ult: UltType = UltType.BARRETT 

# State
var can_dodge: bool = true
var can_grenade: bool = true
var ultimate_charge: float = 100.0 
var is_dodging: bool = false
const MAX_THROW_DIST = 400.0 

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

# Blink State
var is_aiming_blink: bool = false

func _process(delta: float) -> void:
	if is_aiming_blink:
		queue_redraw()

func _draw() -> void:
	if is_aiming_blink:
		# Draw range circle relative to player (0,0 local)
		draw_circle(Vector2.ZERO, MAX_BLINK_DIST, Color(0.2, 0.6, 1.0, 0.15))
		draw_arc(Vector2.ZERO, MAX_BLINK_DIST, 0, TAU, 64, Color(0.2, 0.6, 1.0, 0.5), 2.0)
		
		# Optional: Draw line to cursor
		var mouse_local = get_local_mouse_position()
		var dir = mouse_local.normalized()
		var dist = min(mouse_local.length(), MAX_BLINK_DIST)
		draw_line(Vector2.ZERO, dir * dist, Color(0.2, 0.6, 1.0, 0.5), 2.0)

# ... (Existing code) ...



# Skin Tones
const SKIN_COLORS = [
	Color(0.96, 0.80, 0.60), 
	Color(0.80, 0.60, 0.40), 
	Color(0.50, 0.35, 0.20)  
]

func _ready() -> void:
	add_to_group("player")
	
	chest_sprite.scale = Vector2(0.8, 0.8)
	
	# Init Loadout
	if has_node("/root/SaveSystem"):
		set_skin_tone(SaveSystem.get_skin_tone())
		
		# Load equipped items
		var outfit_ids = SaveSystem.get_equipped_items()
		if "chest_hoodie_red" in outfit_ids.values():
			equip_item(load("res://Assets/Items/Chest/HoodieRed.tres"))
		elif "chest_hoodie_blue" in outfit_ids.values():
			equip_item(load("res://Assets/Items/Chest/HoodieBlue.tres"))
	else:
		set_skin_tone(0)

	# Initialize Weapon
	equip_kit(current_kit)

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
		Kit.MELEE:
			var sword = SWORD_SCENE.instantiate()
			weapon_pivot.add_child(sword)
			active_sword = sword
			print("Equipped Sword")
		Kit.MAGE:
			print("Equipped Mage Staff")

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

func movement() -> void:
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * speed

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
			else:
				perform_dodge() # Gun/Melee Roll (Immediate)

	if event.is_action_released("dodge"):
		if is_aiming_blink:
			is_aiming_blink = false
			queue_redraw()
			perform_blink()
		
	if event.is_action_pressed("ability"):
		if current_kit == Kit.GUN and can_grenade:
			throw_grenade()
		
	if event.is_action_pressed("ultimate"):
		if ultimate_charge >= 100.0:
			fire_ultimate()

	# DEBUG: Kit Switching
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: equip_kit(Kit.GUN)
		if event.keycode == KEY_2: equip_kit(Kit.MELEE)
		if event.keycode == KEY_3: equip_kit(Kit.MAGE)
		if event.keycode == KEY_0:
			# Toggle Ult
			if current_ult == UltType.BARRETT:
				current_ult = UltType.BAZOOKA
				print("DEBUG: Switched to BAZOOKA")
			else:
				current_ult = UltType.BARRETT
				print("DEBUG: Switched to BARRETT")
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
		
		attack_cooldown = FIRE_RATE_GUN
		
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
		
		attack_cooldown = FIRE_RATE_MAGE
		print("Magic Missile Fired!")

const SLASH_SCENE = preload("res://Scenes/Characters/SlashProjectile.tscn")

func swing_sword() -> void:
	var slash = SLASH_SCENE.instantiate()
	get_parent().add_child(slash)
	slash.global_position = weapon_pivot.global_position
	slash.global_rotation = weapon_pivot.global_rotation
	
	attack_cooldown = FIRE_RATE_SWORD
	
	if active_sword and active_sword.has_method("swing"):
		active_sword.swing()
		
	print("Slash Fired!")

func perform_dodge() -> void:
	# Standard Dodge Roll
	is_dodging = true
	can_dodge = false
	velocity = velocity.normalized() * (speed * 2.0)
	visuals.modulate.a = 0.5
	
	cooldown_updated.emit("dodge", 1.0)
	var tw = create_tween()
	tw.tween_method(func(v): cooldown_updated.emit("dodge", v), 1.0, 0.0, 1.0)
	
	await get_tree().create_timer(0.2).timeout
	is_dodging = false
	visuals.modulate.a = 1.0
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.8).timeout
	can_dodge = true

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

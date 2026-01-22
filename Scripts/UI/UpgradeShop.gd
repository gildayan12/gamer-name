extends Control

signal upgrade_selected(upgrade_type)

# Kit-Specific Upgrades (Tier 1 - Wave Clear)
const UPGRADES = [
	# Weapon Upgrades
	{"name": "Trigger Happy", "desc": "Weapons fire 20% faster", "type": "weapon_rate", "val": 0.2, "kits": [0,1,2]},
	{"name": "Heavy Caliber", "desc": "Weapons deal 20% more damage", "type": "weapon_dmg", "val": 0.2, "kits": [0,1,2]},
	{"name": "Extended Mag", "desc": "Increase Magazine Size by 2", "type": "mag_size", "val": 2, "kits": [0]}, # Gun Only
	
	# Ability Upgrades
	{"name": "Power Surge", "desc": "Abilities deal 20% more damage", "type": "ability_dmg", "val": 0.2, "kits": [0,1,2]},
	{"name": "Quick Thinking", "desc": "Abilities recharge 15% faster", "type": "ability_cdr", "val": 0.15, "kits": [0,1,2]},
	# {"name": "Wide Area", "desc": "Increase Effect Radius by 20%", "type": "ability_radius", "val": 0.2, "kits": [0,1,2]}, # REMOVED per request
	
	# Utility / Special
	{"name": "Shrapnel", "desc": "+25% Grenade Radius", "type": "ability_radius", "val": 0.25, "kits": [0]}, # Gun Only
	{"name": "Multicast", "desc": "Throw +1 Grenade", "type": "ability_utility", "val": 1, "kits": [0]},
	{"name": "Overload", "desc": "Chain Lightning bounces +2 more times", "type": "ability_utility", "val": 2, "kits": [2]},
	{"name": "Tremors", "desc": "+25% Shockwave Radius", "type": "ability_radius", "val": 0.25, "kits": [1]}, # Melee Radius specific
	
	# Defence / Movement
	{"name": "Lightweight", "desc": "Move 10% faster", "type": "move_speed", "val": 0.1, "kits": [0,1,2]},
	{"name": "Agility", "desc": "Dodge recharges 20% faster", "type": "dodge_cdr", "val": 0.2, "kits": [0,1,2]},
	{"name": "Reinforced", "desc": "+25% Shield Health", "type": "shield_hp", "val": 0.25, "kits": [1]} # Melee Only
]

var offered_upgrades = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Ensure this runs when paused
	get_tree().paused = true # Pause the game world
	
	generate_cards()
	
	%Card1.pressed.connect(func(): select_upgrade(0))
	%Card2.pressed.connect(func(): select_upgrade(1))
	%Card3.pressed.connect(func(): select_upgrade(2))

func generate_cards() -> void:
	# Cleanup any dynamic cards from previous runs
	for child in $CardContainer.get_children():
		if not child.name.begins_with("Card"): # Keep Card1, Card2, Card3
			child.queue_free()

	offered_upgrades.clear()
	var current_kit = 0
	
	# Get Player for kit and HP check
	var player = get_tree().get_first_node_in_group("player")
	if GameLoop: 
		current_kit = GameLoop.selected_kit
	elif player:
		current_kit = player.current_kit
	
	# Filter relevant upgrades
	var relevant_pool = []
	for u in UPGRADES:
		if current_kit in u["kits"]:
			relevant_pool.append(u)
			
	relevant_pool.shuffle()
	
	# Check for Heal Condition
	var needs_heal = false
	if player and player.hp < player.max_hp:
		needs_heal = true
	
	# Determine names
	var kit_name = "Weapon"
	var move_name = "Dodge"
	var fire_term = "fire"
	
	match current_kit:
		0: # Gun
			kit_name = "Gun"
			move_name = "Dodge Roll"
			fire_term = "fires"
		1: # Melee
			kit_name = "Sword"
			move_name = "Shield"
			fire_term = "swings"
		2: # Mage
			kit_name = "Staff"
			move_name = "Blink"
			fire_term = "casts"

	# Pick 3 standard upgrades
	for i in range(3):
		if relevant_pool.is_empty(): break
		offered_upgrades.append(relevant_pool.pop_front())
		
	# Add Heal if needed
	if needs_heal:
		offered_upgrades.append({
			"name": "Emergency Aid",
			"desc": "Recover +40 HP immediately.",
			"type": "heal",
			"val": 40
		})

	# Display Cards
	for i in range(offered_upgrades.size()):
		var upg = offered_upgrades[i]
		var btn: Button
		
		if i < 3:
			btn = get_node("%Card" + str(i+1))
			# Ensure visible if it was hidden (though unlikely here)
			btn.show()
		else:
			# Create dynamic button for 4th slot
			btn = %Card1.duplicate()
			btn.name = "DynamicCard" + str(i)
			$CardContainer.add_child(btn)
			# We need to connect signal for new button
			btn.pressed.connect(func(): select_upgrade(i))
		
		# Setup Text
		var desc = upg["desc"]
		desc = desc.replace("Weapons", kit_name)
		desc = desc.replace("fire", fire_term)
		desc = desc.replace("Dodge", move_name)
		
		# Heal Styling Override
		if upg["type"] == "heal":
			btn.modulate = Color(0.5, 1.0, 0.5) # Tint Green
		else:
			btn.modulate = Color.WHITE
		
		btn.text = upg["name"] + "\n\n" + desc


func select_upgrade(index: int) -> void:
	if index >= offered_upgrades.size(): return
	
	var choice = offered_upgrades[index]
	print("Upgrade Selected: ", choice["name"])
	
	apply_upgrade(choice)
	
	close_shop()

func apply_upgrade(upg: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	match upg["type"]:
		"weapon_rate":
			player.attack_speed_modifier += upg["val"]
		"weapon_dmg":
			player.weapon_damage_modifier *= (1.0 + upg["val"])
		"mag_size":
			player.magazine_size_modifier += int(upg["val"])
			var effective_max = player.max_ammo + player.magazine_size_modifier
			player.current_ammo = effective_max # Auto-Fill
			player.ammo_updated.emit(player.current_ammo, effective_max)
		"ability_dmg":
			player.ability_damage_modifier *= (1.0 + upg["val"])
		"ability_cdr":
			player.cooldown_modifier -= upg["val"]
			player.cooldown_modifier = max(player.cooldown_modifier, 0.5)
		"ability_utility":
			player.ability_count_modifier += int(upg["val"])
		"ability_radius":
			player.ability_radius_modifier += upg["val"]
		"move_speed":
			player.move_speed_modifier += upg["val"]
		"dodge_cdr":
			player.dodge_cooldown_modifier -= upg["val"]
			player.dodge_cooldown_modifier = max(player.dodge_cooldown_modifier, 0.5)
		"shield_hp":
			player.max_shield_modifier += upg["val"]
		"heal":
			player.heal(int(upg["val"]))

func close_shop() -> void:
	get_tree().paused = false
	upgrade_selected.emit(null) # Signal to WaveManager
	queue_free()

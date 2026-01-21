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
	offered_upgrades.clear()
	var current_kit = 0
	if GameLoop: current_kit = GameLoop.selected_kit
	
	# Filter relevant upgrades
	var relevant_pool = []
	for u in UPGRADES:
		if current_kit in u["kits"]:
			relevant_pool.append(u)
			
	relevant_pool.shuffle()
	
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

	for i in range(3):
		if relevant_pool.is_empty(): break
		var upg = relevant_pool.pop_front()
		offered_upgrades.append(upg)
		
		var btn = get_node_or_null("%Card" + str(i+1))
		if btn:
			var desc = upg["desc"]
			# Dynamic Text Replacement
			desc = desc.replace("Weapons", kit_name)
			desc = desc.replace("fire", fire_term)
			desc = desc.replace("Dodge", move_name)
			
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
			player.weapon_damage_modifier += upg["val"]
		"mag_size":
			player.magazine_size_modifier += int(upg["val"])
		"ability_dmg":
			player.ability_damage_modifier += upg["val"]
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

func close_shop() -> void:
	get_tree().paused = false
	upgrade_selected.emit(null) # Signal to WaveManager
	queue_free()

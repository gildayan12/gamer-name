extends Node

# Signal to notify other systems when data changes
signal data_loaded

const SAVE_PATH = "user://savegame.json"

# Data/Schema
var current_data = {
	"currency": 0,
	"unlocked_items": [], # Array of String IDs
	"current_skin_tone": 0, # Int index
	"current_outfit_id": "", # String ID
	"high_score": 0,
	"is_character_created": false,
	"kit_xp": {
		"0": 0, "1": 0, "2": 0
	},
	"kit_levels": {
		"0": 1, "1": 1, "2": 1
	}
}

func get_xp(kit_id: int) -> int:
	var k = str(kit_id)
	if not "kit_xp" in current_data: current_data["kit_xp"] = {}
	return current_data["kit_xp"].get(k, 0)

func get_level(kit_id: int) -> int:
	var k = str(kit_id)
	if not "kit_levels" in current_data: current_data["kit_levels"] = {}
	return current_data["kit_levels"].get(k, 1)

func add_xp(kit_id: int, amount: int) -> void:
	var k = str(kit_id)
	var current_xp = get_xp(kit_id)
	var current_lvl = get_level(kit_id)
	
	current_xp += amount
	
	# Check Level Up
	# Formula: Level * 1000 XP required per level
	var xp_required = current_lvl * 1000
	
	while current_xp >= xp_required:
		current_xp -= xp_required
		current_lvl += 1
		xp_required = current_lvl * 1000
		print("KIT LEVEL UP! Kit:", k, " New Level:", current_lvl)
		
		# FUTURE: Here is where we check for Rewards (Banners, Skins)
		
	if not "kit_xp" in current_data: current_data["kit_xp"] = {}
	if not "kit_levels" in current_data: current_data["kit_levels"] = {}
	
	current_data["kit_xp"][k] = current_xp
	current_data["kit_levels"][k] = current_lvl
	save_data()

func _ready() -> void:
	load_data()

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(current_data)
		file.store_string(json_string)
		file.close()
		print("Data Saved!")

func load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var parse_result = JSON.parse_string(json_string)
			
			if parse_result is Dictionary:
				# Merge loaded data with default (in case of new fields)
				current_data.merge(parse_result, true)
				print("Data Loaded: ", current_data)
				emit_signal("data_loaded")
			else:
				print("Failed to parse save file.")
	else:
		print("No save file found. Using defaults.")

# Helper Getters/Setters
func set_skin_tone(index: int) -> void:
	current_data["current_skin_tone"] = index
	save_data()

func get_skin_tone() -> int:
	return current_data.get("current_skin_tone", 0)

# Core Loot Logic
func grant_item(item_id: String) -> String:
	# Returns "NEW" or "DUPLICATE" for UI feedback
	if item_id in current_data["unlocked_items"]:
		# Duplicate! Convert to coins.
		var duplicate_reward = 50 # Example value, could be based on item rarity
		add_currency(duplicate_reward)
		print("Duplicate item! Converted to ", duplicate_reward, " coins.")
		return "DUPLICATE"
	else:
		# New Item!
		current_data["unlocked_items"].append(item_id)
		save_data()
		print("New item unlocked: ", item_id)
		return "NEW"

func add_currency(amount: int) -> void:
	current_data["currency"] += amount
	save_data()

func is_item_unlocked(item_id: String) -> bool:
	return item_id in current_data["unlocked_items"]

# Equipment Management
func equip_item_id(slot_idx: int, item_id: String) -> void:
	# Dictionary of Slot Enum (int) -> Item ID (String)
	if not "equipped" in current_data:
		current_data["equipped"] = {}
	
	current_data["equipped"][str(slot_idx)] = item_id # JSON keys must be strings
	save_data()

func get_equipped_items() -> Dictionary:
	return current_data.get("equipped", {})

func set_character_created(value: bool) -> void:
	current_data["is_character_created"] = value
	save_data()

func is_character_created() -> bool:
	return current_data.get("is_character_created", false)

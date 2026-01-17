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
	"high_score": 0
}

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



extends Node

# Global State for the Run
enum Kit { GUN, MELEE, MAGE }
var selected_kit: Kit = Kit.GUN

# Progression Stat Data
var current_wave: int = 1
var run_active: bool = false
var boss_tokens: int = 0

# Tier 2 Stats (Reset on run start)
var global_stats: Dictionary = {
	"strength": 0,
	"dexterity": 0,
	"intelligence": 0
}

func start_new_run(kit: Kit) -> void:
	selected_kit = kit
	current_wave = 1
	run_active = true
	boss_tokens = 0
	
	# Reset Global Stats (Start fresh)
	global_stats = { "strength": 0, "dexterity": 0, "intelligence": 0 }
	
	# Reset Run State
	is_time_frozen = false
	
	print("GameLoop: Starting Run with Kit: ", kit)

func get_selected_kit() -> int:
	return selected_kit

# Global Abilities State
var is_time_frozen: bool = false

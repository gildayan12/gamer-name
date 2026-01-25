extends Node

# Phase 3: Visual Design & Assets
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
	
	# Start Background Music
	AudioManager.play_music("bgm_gameplay")
	
	# Reset Global Stats (Start fresh)
	global_stats = { "strength": 0, "dexterity": 0, "intelligence": 0 }
	
	# Reset Run State
	is_time_frozen = false
	
	# Reset Session Stats
	session_stats = {
		"kills": 0,
		"boss_kills": 0,
		"damage_taken": 0,
		"start_time": Time.get_ticks_msec(),
		"end_time": 0
	}
	
	print("GameLoop: Starting Run with Kit: ", kit)


func get_selected_kit() -> int:
	return selected_kit

# Global Abilities State
var is_time_frozen: bool = false

# --- XP & Session Stats ---
var session_stats: Dictionary = {
	"kills": 0,
	"boss_kills": 0,
	"damage_taken": 0,
	"start_time": 0,
	"end_time": 0
}

func report_kill(is_boss: bool = false) -> void:
	if not run_active: return
	if is_boss:
		session_stats["boss_kills"] += 1
		AudioManager.play_sfx("xp_collect", 0.5) # Deeper sound for boss?
	else:
		session_stats["kills"] += 1
		AudioManager.play_sfx("xp_collect", 1.0 + randf() * 0.2) # Pitch variation

func report_damage_taken(amount: int) -> void:
	if not run_active: return
	session_stats["damage_taken"] += amount

func calculate_xp() -> int:
	var duration_sec = (Time.get_ticks_msec() - session_stats["start_time"]) / 1000.0
	if session_stats["end_time"] > 0:
		duration_sec = (session_stats["end_time"] - session_stats["start_time"]) / 1000.0
		
	var xp = 0
	xp += session_stats["kills"] * 5
	xp += session_stats["boss_kills"] * 100
	xp += int(duration_sec * 1.5) # 1.5 XP per second survived
	
	# Penalty for Taking Damage (Optional, maybe just bonus for NOT taking damage?)
	# Let's keep it simple: No penalty for now, just rewards.
	
	print("XP Calculation: Kills(", session_stats["kills"], ") Boss(", session_stats["boss_kills"], ") Time(", int(duration_sec), "s) = ", xp)
	return xp

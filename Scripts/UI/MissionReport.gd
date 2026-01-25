extends Control

@onready var title_label: Label = %TitleLabel
@onready var stats_container: VBoxContainer = %StatsContainer
@onready var xp_label: Label = %XPLabel
@onready var level_bar: ProgressBar = %LevelBar
@onready var level_text: Label = %LevelText
@onready var continue_btn: Button = %ContinueBtn

var xp_gained: int = 0
var start_xp: int = 0
var current_level: int = 1

func setup(is_win: bool) -> void:
	# 1. Title
	if is_win:
		title_label.text = "MISSION ACCOMPLISHED"
		title_label.modulate = Color.GOLD
		AudioManager.play_sfx("game_win")
	else:
		title_label.text = "YOU DIED\n(Cause of Death: SKILL ISSUE)"
		title_label.modulate = Color.RED
		AudioManager.play_sfx("game_lose")
		
	# 2. Get Data
	if GameLoop:
		xp_gained = GameLoop.calculate_xp()
		GameLoop.session_stats["end_time"] = Time.get_ticks_msec() # Ensure end time is set if not already
		populate_stats(GameLoop.session_stats)
	
	# 3. Get Save Data
	var kit_id = 0
	if GameLoop:
		kit_id = int(GameLoop.selected_kit)
		
	if SaveSystem:
		start_xp = SaveSystem.get_xp(kit_id)
		current_level = SaveSystem.get_level(kit_id)
	
	# 4. Display Initial State
	var kit_name = ["GUN", "MELEE", "MAGE"][kit_id]
	xp_label.text = "XP GAINED: 0"
	level_text.text = kit_name + " LEVEL " + str(current_level)
	level_bar.value = calculate_bar_percent(start_xp)
	
	# 5. Start Animation Sequence
	animate_sequence(kit_id)

func populate_stats(stats: Dictionary) -> void:
    # ... (Same logic, omitted for brevity)
	# Helper to create rows
	add_stat_row("Enemies Neutralized", str(stats["kills"]), "+ " + str(stats["kills"] * 5))
	add_stat_row("HVT Eliminated", str(stats["boss_kills"]), "+ " + str(stats["boss_kills"] * 100))
	
	var duration = (stats["end_time"] - stats["start_time"]) / 1000.0
	add_stat_row("Survival Time", str(int(duration)) + "s", "+ " + str(int(duration * 1.5)))

func add_stat_row(label: String, value: String, bonus: String) -> void:
	var hbox = HBoxContainer.new()
	
	var l = Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(l)
	
	var v = Label.new()
	v.text = value
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(v)
	
	var b = Label.new()
	b.text = bonus
	b.modulate = Color.GREEN
	hbox.add_child(b)
	
	stats_container.add_child(hbox)

func calculate_bar_percent(total_xp: int) -> float:
	# Simple formula: Level requires Level * 1000 XP
	# This logic needs to match SaveSystem's logic if complex
	# For visual bar only:
	var xp_for_next = current_level * 1000
	var xp_in_level = total_xp % 1000 # Rough approximation for now
	return (float(xp_in_level) / 1000.0) * 100.0

func animate_sequence(kit_id: int) -> void:
	var tw = create_tween()
	
	# Count up XP
	tw.tween_method(func(v): xp_label.text = "XP GAINED: " + str(int(v)), 0, xp_gained, 1.5)
	
	# Fill Bar
	# Note: Real implementation needs to handle Level Up wrapping
	# For MVP, we just fill it visually
	await tw.finished
	
	var final_xp = start_xp + xp_gained
	var new_level = current_level + (final_xp / 1000) - (start_xp / 1000) # Quick maths
	
	# Rewards Database (Placeholder)
	# Nested Dict: [KitID][Level] -> Reward Name
	var REWARDS_DB = {
		0: { # Gun
			2: "New Banner (Glock)",
			5: "Weapon Skin (Golden Gun)",
			10: "Outfit (Cowboy)"
		},
		1: { # Melee
			2: "New Banner (Blade)",
			5: "Sword Skin (Laser)",
			10: "Outfit (Samurai)"
		},
		2: { # Mage
			2: "New Banner (Sigil)",
			5: "Magic Color (Purple)",
			10: "Outfit (Wizard)"
		}
	}
	
	if new_level > current_level:
		level_text.text = "LEVEL UP! " + str(new_level)
		level_text.modulate = Color.GREEN
		AudioManager.play_sfx("level_up")
		
		# Check for Reward
		var kit_rewards = REWARDS_DB.get(kit_id, {})
		# Check all levels we passed through (e.g. if we jumped from 1 to 3, check 2 and 3)
		for lvl in range(current_level + 1, new_level + 1):
			if lvl in kit_rewards:
				var reward_name = kit_rewards[lvl]
				level_text.text += "\nUNLOCKED: " + reward_name + " (Coming Soon)"
				# Logic to actually grant item would go here: SaveSystem.grant_item(item_id)
		
		
	# Save
	if SaveSystem:
		SaveSystem.add_xp(kit_id, xp_gained)
	
	continue_btn.visible = true

func _on_continue_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

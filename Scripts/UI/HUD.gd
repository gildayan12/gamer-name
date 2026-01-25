extends CanvasLayer

@onready var hp_bar: ProgressBar = %HPBar
@onready var grid_stats: GridContainer = %GridStats

@onready var dodge_bar: ProgressBar = %DodgeBar
@onready var ability_bar: ProgressBar = %AbilityBar
@onready var ult_bar: ProgressBar = %UltBar
@onready var stat_label: Label = %StatLabel

var player_ref: Node2D = null
var stat_labels: Dictionary = {}

@onready var game_over_screen: Control = %GameOverScreen
@onready var wave_label: Label = %WaveLabel
@onready var retry_btn: Button = %RetryBtn
@onready var menu_btn: Button = %MenuBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Ensure Game Over connects when paused
	add_to_group("hud")
	
	# Initialize Stat Grid Labels
	var stats = ["DMG", "WD", "AP", "SPD", "MOV", "CDR", "HP"]
	for s in stats:
		var l_name = Label.new()
		l_name.text = s + ":"
		l_name.modulate = Color(0.7, 0.7, 0.7) # Greyish
		grid_stats.add_child(l_name)
		
		var l_val = Label.new()
		l_val.text = "-"
		grid_stats.add_child(l_val)
		stat_labels[s] = l_val

	# Style the HP Bar (Red)
	if hp_bar:
		var sb_hp = StyleBoxFlat.new()
		sb_hp.bg_color = Color(1.0, 0.1, 0.1, 1.0) # Bright Red
		sb_hp.corner_radius_top_left = 4
		sb_hp.corner_radius_top_right = 4
		sb_hp.corner_radius_bottom_right = 4
		sb_hp.corner_radius_bottom_left = 4
		hp_bar.add_theme_stylebox_override("fill", sb_hp)

	# Buttons
	if retry_btn:
		retry_btn.pressed.connect(on_retry)
	if menu_btn:
		menu_btn.pressed.connect(on_menu)

	# DEBUG BUTTON
	var debug_btn = Button.new()
	debug_btn.text = "DEBUG: WIN WAVE 5"
	debug_btn.position = Vector2(50, 200) # Left side
	debug_btn.pressed.connect(on_debug_win)
	add_child(debug_btn)

	# Style the Ult Bar (Gold/Orange)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.65, 0.0, 1.0) # Orange
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	if ult_bar:
		ult_bar.add_theme_stylebox_override("fill", sb)

	# Find player and connect...
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		player_ref = player
		# ... (Existing connections)
		if player.has_signal("cooldown_updated"):
			player.cooldown_updated.connect(update_cooldown)
		if player.has_signal("ultimate_updated"):
			player.ultimate_updated.connect(update_ult)
		if player.has_signal("ammo_updated"):
			player.ammo_updated.connect(update_ammo)
		if player.has_signal("shield_updated"):
			player.shield_updated.connect(update_shield)
		
		# Sync initial value
		if player.get("ultimate_charge") != null:
			update_ult(player.ultimate_charge)
			
		if player.has_method("update_hud_stats"):
			player.update_hud_stats()
			
	# Dynamic Labels (Existing logic)
	if GameLoop:
		var dodge_label_node = %DodgeBar.get_parent().get_node_or_null("Label")
		var ability_label_node = %AbilityBar.get_parent().get_node_or_null("Label")
		
		if dodge_label_node and ability_label_node:
			match GameLoop.selected_kit:
				0: # Gun
					dodge_label_node.text = "DODGE"
					ability_label_node.text = "NADE"
					if stat_label: stat_label.visible = true
				1: # Melee
					dodge_label_node.text = "SHIELD"
					ability_label_node.text = "SLAM"
					if stat_label: stat_label.visible = true
				2: # Mage
					dodge_label_node.text = "BLINK"
					ability_label_node.text = "ZAP"
					if stat_label: stat_label.visible = false

const MISSION_REPORT_SCENE = preload("res://Scenes/UI/MissionReport.tscn")

func show_game_over(waves: int) -> void:
	# game_over_screen.visible = true # Old screen
	# wave_label.text = "Waves Survived: " + str(waves - 1)
	
	if MISSION_REPORT_SCENE:
		var report = MISSION_REPORT_SCENE.instantiate()
		add_child(report)
		report.setup(false) # false = Loss/Death
		
	get_tree().paused = true # Pause everything

func on_retry() -> void:
	print("Retry Clicked")
	get_tree().paused = false
	if GameLoop:
		GameLoop.start_new_run(GameLoop.selected_kit)
		# Reload Main Scene
		get_tree().reload_current_scene()

func on_menu() -> void:
	print("Menu Clicked")
	get_tree().paused = false
	# Change to MainMenu scene
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

func on_debug_win() -> void:
	var wm = get_tree().get_first_node_in_group("wave_manager")
	if wm:
		wm.debug_skip_to_wave_5_end()

func update_cooldown(type: String, value: float) -> void:
	# Value is 0.0 (Ready) to 1.0 (Full cooldown)
	# We invert it for the bar (1.0 = Ready, 0.0 = Empty)
	var display_value = (1.0 - value) * 100
	
	match type:
		"dodge": dodge_bar.value = display_value
		"shroom": ability_bar.value = display_value 

func update_ult(value: float) -> void:
	# Value is 0-100
	ult_bar.value = value

func update_ammo(curr, max_v):
	if GameLoop and GameLoop.selected_kit != 0: return # Only update for GUN
	if stat_label: stat_label.text = "AMMO: %d / %d" % [curr, max_v]

func update_shield(curr, _max_v):
	if GameLoop and GameLoop.selected_kit != 1: return # Only update for MELEE
	if stat_label: stat_label.text = "SHIELD: %d" % curr

func _process(_delta: float) -> void:
	if not player_ref: return
	
	# Update HP Bar
	if hp_bar:
		hp_bar.max_value = player_ref.max_hp
		hp_bar.value = player_ref.hp
		
		# Update HP Text 
		var hp_lbl = hp_bar.get_node_or_null("HPLabel") 
		if hp_lbl:
			hp_lbl.text = "%d / %d" % [int(player_ref.hp), int(player_ref.max_hp)]
	
	# Update Stats
	if not stat_labels.is_empty():
		# DMG (Global Strength)
		stat_labels["DMG"].text = "x%.1f" % player_ref.global_damage_modifier
		
		# WD (Weapon Damage Upgrade)
		stat_labels["WD"].text = "x%.1f" % player_ref.weapon_damage_modifier
		
		# AP
		stat_labels["AP"].text = "x%.1f" % player_ref.ability_damage_modifier
		
		# AP
		stat_labels["AP"].text = "x%.1f" % player_ref.ability_damage_modifier
		
		# SPD (Global Stat Level - Dex)
		if GameLoop:
			stat_labels["SPD"].text = "Lvl " + str(GameLoop.global_stats["dexterity"])
		
		# MOV (Total Move Speed)
		var m_spd = player_ref.move_speed_modifier * (1.0 + (GameLoop.global_stats["dexterity"] * 0.05))
		stat_labels["MOV"].text = "x%.1f" % m_spd
		
		# CDR
		var cdr = (1.0 - player_ref.cooldown_modifier) * 100
		stat_labels["CDR"].text = "-%d%%" % int(cdr)
		
		# HP (Max HP)
		stat_labels["HP"].text = "%d" % int(player_ref.max_hp)

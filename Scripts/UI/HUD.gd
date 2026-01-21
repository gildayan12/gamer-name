extends CanvasLayer

@onready var dodge_bar: ProgressBar = %DodgeBar
@onready var ability_bar: ProgressBar = %AbilityBar
@onready var ult_bar: ProgressBar = %UltBar
@onready var stat_label: Label = %StatLabel

@onready var game_over_screen: Control = %GameOverScreen
@onready var wave_label: Label = %WaveLabel
@onready var retry_btn: Button = %RetryBtn
@onready var menu_btn: Button = %MenuBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Ensure Game Over connects when paused
	add_to_group("hud")
	
	# Buttons
	if retry_btn:
		retry_btn.pressed.connect(on_retry)
	if menu_btn:
		menu_btn.pressed.connect(on_menu)

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

func show_game_over(waves: int) -> void:
	game_over_screen.visible = true
	wave_label.text = "Waves Survived: " + str(waves - 1)
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
	if stat_label: stat_label.text = "AMMO: %d / %d" % [curr, max_v]

func update_shield(curr, _max_v):
	if stat_label: stat_label.text = "SHIELD: %d" % curr

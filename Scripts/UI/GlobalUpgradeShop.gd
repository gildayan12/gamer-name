extends Control

signal shop_closed

@onready var token_label: Label = %TokenLabel
@onready var strength_btn: Button = %StrengthButton
@onready var dexterity_btn: Button = %DexterityButton
@onready var intelligence_btn: Button = %IntelligenceButton
@onready var continue_btn: Button = %ContinueButton

@onready var str_val_label: Label = %StrValue
@onready var dex_val_label: Label = %DexValue
@onready var int_val_label: Label = %IntValue

func _ready() -> void:
	update_ui()
	
	# Connect Signals
	strength_btn.pressed.connect(func(): buy_stat("strength"))
	dexterity_btn.pressed.connect(func(): buy_stat("dexterity"))
	intelligence_btn.pressed.connect(func(): buy_stat("intelligence"))
	
	# Right Click to Refund
	strength_btn.gui_input.connect(func(ev): check_refund(ev, "strength"))
	dexterity_btn.gui_input.connect(func(ev): check_refund(ev, "dexterity"))
	intelligence_btn.gui_input.connect(func(ev): check_refund(ev, "intelligence"))
	
	continue_btn.pressed.connect(close_shop)
	
	# Disable Player Input
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.input_enabled = false

func update_ui() -> void:
	token_label.text = "BOSS TOKENS: " + str(GameLoop.boss_tokens)
	
	str_val_label.text = "DMG Lvl " + str(GameLoop.global_stats["strength"]) + "\n(R-Click to Refund)"
	dex_val_label.text = "SPD Lvl " + str(GameLoop.global_stats["dexterity"]) + "\n(R-Click to Refund)"
	int_val_label.text = "HP Lvl " + str(GameLoop.global_stats["intelligence"]) + "\n(R-Click to Refund)"
	
	# Enable/Disable buttons based on cost
	var can_buy = GameLoop.boss_tokens > 0
	strength_btn.disabled = not can_buy
	dexterity_btn.disabled = not can_buy
	intelligence_btn.disabled = not can_buy
	
	# Re-enable if we have stats to sell (Logic override for Disabled buttons?)
	# Actually, if disabled, gui_input might not fire? 
	# Buttons disabled means PRESSED doesn't fire. gui_input usually still works unless mouse_filter is ignore.
	# Standard Button disabled allows no input. 
	# Workaround: Don't disable button fully, just visuals? Or check if Godot buttons allow gui_input when disabled.
	# Default Godot: Disabled buttons consume input or ignore it. 
	# Let's set mouse_filter to STOP if disabled? 
	# Simpler: If disabled, toggle disabled off but visually dim? 
	# Let's simply NOT disable them if they have levels, or rely on 'can_buy' check inside 'buy_stat'
	
	strength_btn.disabled = false 
	dexterity_btn.disabled = false
	intelligence_btn.disabled = false
	
	# Visual indication of affordable
	if not can_buy:
		strength_btn.modulate = Color(0.5, 0.5, 0.5)
		dexterity_btn.modulate = Color(0.5, 0.5, 0.5)
		intelligence_btn.modulate = Color(0.5, 0.5, 0.5)
	else:
		strength_btn.modulate = Color(1, 1, 1)
		dexterity_btn.modulate = Color(1, 1, 1)
		intelligence_btn.modulate = Color(1, 1, 1)
	
	# Continue is always available
	if GameLoop.boss_tokens == 0:
		continue_btn.modulate = Color(0, 1, 0) # Green light
	else:
		continue_btn.modulate = Color.WHITE

func buy_stat(stat_name: String) -> void:
	if GameLoop.boss_tokens > 0:
		GameLoop.boss_tokens -= 1
		GameLoop.global_stats[stat_name] += 1
		print("Bought " + stat_name + "! New Level: ", GameLoop.global_stats[stat_name])
		update_ui()
		update_player_stats()

func check_refund(event: InputEvent, stat_name: String) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			print("Right Click detected on ", stat_name)
			sell_stat(stat_name)
			get_viewport().set_input_as_handled()

func sell_stat(stat_name: String) -> void:
	if GameLoop.global_stats[stat_name] > 0:
		GameLoop.global_stats[stat_name] -= 1
		GameLoop.boss_tokens += 1
		print("Refunded " + stat_name + "! New Level: ", GameLoop.global_stats[stat_name])
		update_ui()
		update_player_stats()

func update_player_stats() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_global_stats"):
		player.apply_global_stats()

func close_shop() -> void:
	visible = false
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.input_enabled = true
		
	shop_closed.emit()

extends Control

@onready var player_preview: CharacterBody2D = %PlayerPreview

# UI Layers
@onready var main_ui: VBoxContainer = $UI
@onready var kit_ui: Control = %KitSelectionUI
@onready var creator_ui: Control = %CharCreatorUI

# Main Buttons
@onready var customization_btn: Button = %CustomizationButton
@onready var message_label: Label = %MessageLabel

var available_items: Array[ApparelItem] = []
var selected_kit: GameLoop.Kit = GameLoop.Kit.GUN
var is_first_run: bool = true

func _ready() -> void:
	# Preview Setup
	player_preview.input_enabled = false
	player_preview.equip_kit(selected_kit) 
	
	load_available_items()
	connect_signals()
	
	# Check Save Data
	if has_node("/root/SaveSystem"):
		var created = SaveSystem.is_character_created()
		is_first_run = not created
	
	update_main_menu_state()

func update_main_menu_state() -> void:
	# Show Main UI, Hide others
	main_ui.visible = true
	kit_ui.visible = false
	creator_ui.visible = false
	message_label.text = ""
	
	# Lock/Unlock Customization
	if is_first_run:
		customization_btn.disabled = true
		customization_btn.modulate = Color(0.5, 0.5, 0.5) # Dimmed
	else:
		customization_btn.disabled = false
		customization_btn.modulate = Color(1, 1, 1)

func _on_play_clicked() -> void:
	if is_first_run:
		# Go to Character Creator
		open_character_creator()
	else:
		# Go to Kit Selection
		open_kit_selection()

func _on_customization_clicked() -> void:
	if is_first_run:
		# Should be disabled, but double check
		message_label.text = "Press PLAY to create your character!"
	else:
		# Or just open the dedicated screen if we kept it.
	# Open the new Skin Locker Scene
		get_tree().change_scene_to_file("res://Scenes/UI/CustomizationScreen.tscn")

func _on_customization_locked_click() -> void:
	# If user tries to click locked customization (handled via button wrapper or custom signal if disabled consumes input)
	# Since button is disabled, we might need a wrapper or just trust the visual queue.
	# Let's add a separate 'hidden' button or just set the label if they try 'Play' logic elsewhere? 
	# User requirement: "when pressed it will say a message". Disabled buttons don't fire 'pressed'.
	# Workaround: Don't disable, just handle logic in pressed.
	pass

func connect_signals() -> void:
	# Main
	%PlayButton.pressed.connect(_on_play_clicked)
	
	# Customization Button Logic
	# We want it clickable even if 'locked' to show message
	customization_btn.pressed.connect(func():
		if is_first_run:
			message_label.text = "Press PLAY to make your character!"
		else:
			get_tree().change_scene_to_file("res://Scenes/UI/CustomizationScreen.tscn")
	)
	
	# Kit Selection
	%GunButton.pressed.connect(func(): _on_kit_selected(GameLoop.Kit.GUN))
	%MeleeButton.pressed.connect(func(): _on_kit_selected(GameLoop.Kit.MELEE))
	%MageButton.pressed.connect(func(): _on_kit_selected(GameLoop.Kit.MAGE))
	%CancelKitButton.pressed.connect(update_main_menu_state) # Back to Main
	
	# Creator Inputs - Skin
	var skin_group = ButtonGroup.new()
	var skin_btns = [%Skin1, %Skin2, %Skin3]
	for i in range(skin_btns.size()):
		var btn = skin_btns[i]
		btn.toggle_mode = true
		btn.button_group = skin_group
		btn.pressed.connect(func(): player_preview.set_skin_tone(i))
	
	# Creator Inputs - Clothes
	var chest_group = ButtonGroup.new()
	var chest_btns = [%HoodieRed, %HoodieBlue]
	for i in range(chest_btns.size()):
		var btn = chest_btns[i]
		btn.toggle_mode = true
		btn.button_group = chest_group
		btn.pressed.connect(func(): player_preview.equip_item(available_items[i]))
	
	%FinishCreatorButton.pressed.connect(_on_finish_creator_pressed)

func open_character_creator(is_edit_mode: bool = false) -> void:
	main_ui.visible = false
	kit_ui.visible = false
	creator_ui.visible = true
	
	if is_edit_mode:
		%FinishCreatorButton.text = "SAVE & BACK"
	else:
		%FinishCreatorButton.text = "FINISH & PLAY"

func open_kit_selection() -> void:
	main_ui.visible = false
	creator_ui.visible = false
	kit_ui.visible = true

func _on_finish_creator_pressed() -> void:
	# Save Character Data (Skin/Outfit is saved automatically by player methods if connected to SaveSystem)
	# But we need to mark 'created'
	
	if is_first_run:
		if has_node("/root/SaveSystem"):
			SaveSystem.set_character_created(true)
		is_first_run = false
		
		# Proceed to Kit Selection immediately? Or back to menu?
		# "on your first run you will make the base... finish... unlocks..."
		# Let's go straight to Kit Selection for smoothness
		open_kit_selection()
	else:
		# Just editing
		update_main_menu_state() # Back to Main

func _on_kit_selected(kit: GameLoop.Kit) -> void:
	# Start Run
	GameLoop.start_new_run(kit)
	get_tree().change_scene_to_file("res://Scenes/Arenas/TestArena.tscn")

func load_available_items() -> void:
	var red = load("res://Assets/Items/Chest/HoodieRed.tres")
	var blue = load("res://Assets/Items/Chest/HoodieBlue.tres")
	if red: available_items.append(red)
	if blue: available_items.append(blue)

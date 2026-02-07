extends Control

@onready var player_preview: CharacterBody2D = %PlayerPreview

# Define paths (Must match what Player.gd expects or valid scenes)
const SKULL_SKIN_PATH: String = "res://Scenes/player_skin_skull.tscn"
# Default fallback (original model)
const DEFAULT_SKIN_PATH: String = "res://Assets/Characters/GunnerAnimations/Player_Idle.glb" 

func _ready() -> void:
	print("CUSTOMIZATION SCREEN LOADED")
	# Disable input for the preview character
	player_preview.input_enabled = false
	
	# SETUP UI (Repurposing existing buttons for now)
	var btn_default = $UI/RedHoodie
	var btn_skull = $UI/BlueHoodie
	var btn_play = $UI/PlayButton
	
	# Hide unused UI elements
	$UI/HBoxContainer.visible = false # Hide Skin Tones
	$UI/SkinLabel.visible = false
	$UI/ClothesLabel.text = "Select Skin"
	
	# Configure Default Button
	btn_default.text = "Default Soldier"
	if not btn_default.pressed.is_connected(_on_default_pressed):
		btn_default.pressed.connect(_on_default_pressed)
	print("Default button connected: ", btn_default.pressed.is_connected(_on_default_pressed))
	
	# Configure Skull Button
	btn_skull.text = "Skull Trooper"
	if not btn_skull.pressed.is_connected(_on_skull_pressed):
		btn_skull.pressed.connect(_on_skull_pressed)
	print("Skull button connected: ", btn_skull.pressed.is_connected(_on_skull_pressed))
	
	# Configure Play/Back Button
	btn_play.text = "BACK TO MENU"
	if btn_play.pressed.is_connected(_on_play_button_pressed):
		btn_play.pressed.disconnect(_on_play_button_pressed)
	if not btn_play.pressed.is_connected(_on_back_pressed):
		btn_play.pressed.connect(_on_back_pressed)
	
	# Load current skin to setup preview
	if GameLoop.selected_skin_path != "":
		player_preview.load_skin_scene(GameLoop.selected_skin_path)
	elif OS.has_feature("editor"): # Default for debug
		player_preview.load_skin_scene(SKULL_SKIN_PATH)

func _on_default_pressed() -> void:
	print(">>> DEFAULT BUTTON PRESSED <<<")
	GameLoop.selected_skin_path = DEFAULT_SKIN_PATH
	player_preview.load_skin_scene(DEFAULT_SKIN_PATH)
	print("Equipped Default Skin")

func _on_skull_pressed() -> void:
	GameLoop.selected_skin_path = SKULL_SKIN_PATH
	player_preview.load_skin_scene(SKULL_SKIN_PATH)
	print("Equipped Skull Skin")

func _on_back_pressed() -> void:
	# Return to Main Menu
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

func _on_play_button_pressed() -> void:
	# Legacy function, kept just in case signal connection in editor persists
	_on_back_pressed()

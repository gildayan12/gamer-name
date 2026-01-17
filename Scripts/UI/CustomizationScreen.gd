extends Control

@onready var player_preview: CharacterBody2D = %PlayerPreview

# Mock database - in a real game, loop through a folder of .tres files
var available_items: Array[ApparelItem] = []

func _ready() -> void:
	# Disable input for the preview character
	player_preview.input_enabled = false
	
	# Connect placeholder buttons manually
	$UI/RedHoodie.pressed.connect(func(): _on_item_pressed(available_items[0]))
	$UI/BlueHoodie.pressed.connect(func(): _on_item_pressed(available_items[1]))

	# Load test items
	load_items_from_disk()
	
	# Load current save state
	if has_node("/root/SaveSystem"):
		var skin_idx = SaveSystem.get_skin_tone()
		player_preview.set_skin_tone(skin_idx)

func load_items_from_disk() -> void:
	# Just manually adding the ones we made for now
	var red = load("res://Assets/Items/Chest/HoodieRed.tres")
	var blue = load("res://Assets/Items/Chest/HoodieBlue.tres")
	if red: available_items.append(red)
	if blue: available_items.append(blue)
	
	# Create logic to populate keys (TODO: Make dynamic buttons)

func _on_skin_button_pressed(index: int) -> void:
	player_preview.set_skin_tone(index)

func _on_item_pressed(item: ApparelItem) -> void:
	player_preview.equip_item(item)
	# Also update SaveSystem 'current_outfit' (todo)

func _on_play_button_pressed() -> void:
	# Transition to Arena
	get_tree().change_scene_to_file("res://Scenes/Arenas/TestArena.tscn")

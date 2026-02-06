extends Node

## SkinManager - Handles loading and caching character skins
## Each skin has 3 views: front, back, side
## Usage: SkinManager.load_skin("skin_name") -> returns Dictionary of textures

var current_skin: String = "default"
var skin_cache: Dictionary = {}

const SKIN_BASE_PATH = "res://Assets/Skins/"

# Parts that make up a character view
# Parts that make up a character view
const PARTS = ["torso", "neck", "head", "upper_arm", "forearm", "thigh", "calf", "foot"]

func _ready() -> void:
	print("SkinManager: Ready")

## Load a skin by name, returns cached version if available
func load_skin(skin_name: String) -> Dictionary:
	if skin_cache.has(skin_name):
		return skin_cache[skin_name]
	
	var base = SKIN_BASE_PATH + skin_name + "/"
	var skin_data = {
		"front": _load_view(base + "front/"),
		"back": _load_view(base + "back/"),
		"side": _load_view(base + "side/")
	}
	
	skin_cache[skin_name] = skin_data
	print("SkinManager: Loaded skin '", skin_name, "'")
	return skin_data

## Load all textures for a single view (front/back/side)
func _load_view(path: String) -> Dictionary:
	var view_data = {}
	
	for part in PARTS:
		# Check PNG first
		var tex_path = path + part + ".png"
		if not ResourceLoader.exists(tex_path):
			# Check JPG second
			tex_path = path + part + ".jpg"
			if not ResourceLoader.exists(tex_path):
				# Check with "side" prefix if loading side view? 
				# Actually let's just stick to standard names.
				view_data[part] = null
				continue
				
		view_data[part] = load(tex_path)
	
	return view_data

## Get the current skin data
func get_current_skin() -> Dictionary:
	return load_skin(current_skin)

## Set and load a new skin
func set_skin(skin_name: String) -> Dictionary:
	current_skin = skin_name
	return load_skin(skin_name)

## List available skins by scanning the Skins folder
func get_available_skins() -> Array:
	var skins = []
	var dir = DirAccess.open(SKIN_BASE_PATH)
	
	if dir:
		dir.list_dir_begin()
		var folder = dir.get_next()
		
		while folder != "":
			if dir.current_is_dir() and not folder.begins_with("."):
				skins.append(folder)
			folder = dir.get_next()
		
		dir.list_dir_end()
	
	return skins

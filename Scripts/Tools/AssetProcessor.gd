extends SceneTree

# ASSET PROCESSOR (Magic Wand / Flood Fill)
# Usage: Run with Godot command line.
# godot --headless -s Scripts/Tools/AssetProcessor.gd

func _init():
	print("--- ASSET PROCESSOR STARTED ---")
	
	# Dynamically scan all JPG files in skin folders
	var tasks = []
	var skins_path = "res://Assets/Skins/"
	var skins_dir = DirAccess.open(skins_path)
	
	if skins_dir:
		skins_dir.list_dir_begin()
		var skin_name = skins_dir.get_next()
		while skin_name != "":
			if skins_dir.current_is_dir() and not skin_name.begins_with("."):
				# For each skin, scan front/back/side folders
				for view in ["side"]:
					var view_path = skins_path + skin_name + "/" + view + "/"
					var view_dir = DirAccess.open(view_path)
					if view_dir:
						view_dir.list_dir_begin()
						var file_name = view_dir.get_next()
						while file_name != "":
							var ext = file_name.get_extension().to_lower()
							if ext == "jpg" or ext == "jpeg" or ext == "png":
								# Skip files that appear to be processed results to avoid loops/double processing
								if "_clean" in file_name: 
									file_name = view_dir.get_next()
									continue
									
								var base_name = file_name.get_basename()
								tasks.append({
									"in": view_path + file_name,
									"out": view_path + base_name + ".png" # Will overwrite original if png
								})
							file_name = view_dir.get_next()
						view_dir.list_dir_end()
			skin_name = skins_dir.get_next()
		skins_dir.list_dir_end()
	
	for task in tasks:
		process_image(task)
	
	print("--- PROCESSING COMPLETE ---")
	quit()

func process_image(task: Dictionary):
	var in_path = task["in"]
	var out_path = task.get("out", "")
	
	# 1. Load Image
	var abs_in = ProjectSettings.globalize_path(in_path)
	var abs_out = ""
	if out_path != "":
		abs_out = ProjectSettings.globalize_path(out_path)
	
	if not FileAccess.file_exists(abs_in):
		print("SKIP: Input file not found: ", abs_in)
		return

	var img = Image.load_from_file(abs_in)
	if not img:
		print("ERROR: Failed to load image: ", abs_in)
		return
		
	print("Processing: ", in_path, " [", img.get_width(), "x", img.get_height(), "]")
	
	# Convert to RGBA8
	img.convert(Image.FORMAT_RGBA8)
	
	var w = img.get_width()
	var h = img.get_height()
	
	# 2. GLOBAL COLOR KEY (Delete Background)
	# DETECT BG COLOR FROM CORNER (0,0)
	var bg_target = img.get_pixel(0, 0)
	
	if bg_target.a == 0.0:
		print("SKIP: Image already has transparent background at (0,0): ", in_path)
		return
	
	# Optional: Skin Target from dictionary
	var skin_target = Color(0.96, 0.80, 0.60)
	var use_skin_removal = false
	if task.has("mode") and task["mode"] == "REMOVE_SKIN":
		use_skin_removal = true
		if task.has("skin_color"): skin_target = task["skin_color"]
	
	var tolerance_bg = 0.35  # Increased to catch more green shades
	var tolerance_skin = 0.2 
	
	print("  > Keying Out BG (Auto-Detected): ", bg_target.to_html())
	
	for y in range(h):
		for x in range(w):
			var col = img.get_pixel(x, y)
			if col.a == 0.0: continue
			
			# Check BG
			if _distance_color(col, bg_target) <= tolerance_bg:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
				
			# Check Skin
			if use_skin_removal:
				if _distance_color(col, skin_target) <= tolerance_skin:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
			
	# 3. EROSION (Shrink by 2 pixels - reduced to preserve outlines)
	for erosion_pass in range(2):
		print("  > Erosing Edges (pass ", erosion_pass + 1, ")...")
		var pixels_to_delete = []
		
		for y in range(h):
			for x in range(w):
				if img.get_pixel(x, y).a > 0.0:
					if _has_transparent_neighbor(img, x, y, w, h):
						pixels_to_delete.append(Vector2i(x, y))
		
		for p in pixels_to_delete:
			img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))

	# 4. DEFRINGE - Remove green-tinted edge pixels (multiple passes)
	for defringe_pass in range(3):
		print("  > Defringing green edges (pass ", defringe_pass + 1, ")...")
		var green_pixels_to_delete = []
		for y in range(h):
			for x in range(w):
				var col = img.get_pixel(x, y)
				if col.a > 0.0:
					# Check if this pixel is near an edge AND has high green
					if _has_transparent_neighbor(img, x, y, w, h):
						# If green channel is higher than red or blue, remove it
						if col.g > col.r + 0.02 and col.g > col.b + 0.02:
							green_pixels_to_delete.append(Vector2i(x, y))
		
		for p in green_pixels_to_delete:
			img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	# 4. Save Output (Standard or Slice)
	if task.has("mode") and task["mode"] == "GRID_SLICE_2X2":
		var prefix = task["out_prefix"]
		var hw = w / 2
		var hh = h / 2
		
		# Order: TL, TR, BL, BR
		var regions = [
			Rect2i(0, 0, hw, hh),
			Rect2i(hw, 0, hw, hh),
			Rect2i(0, hh, hw, hh),
			Rect2i(hw, hh, hw, hh)
		]
		
		for i in range(regions.size()):
			var sub_img = img.get_region(regions[i])
			var sub_path = prefix + "_" + str(i) + ".png"
			var abs_sub = ProjectSettings.globalize_path(sub_path)
			sub_img.save_png(abs_sub)
			print("Saved Slice ", i, ": ", abs_sub)
			
	else:
		# Standard Single Output
		var err = img.save_png(abs_out)
		if err == OK:
			print("SUCCESS: Saved clean image to ", abs_out)
		else:
			print("ERROR: Failed to save PNG. Error code: ", err)

func _has_transparent_neighbor(img: Image, x: int, y: int, w: int, h: int) -> bool:
	if x > 0 and img.get_pixel(x-1, y).a == 0.0: return true
	if x < w-1 and img.get_pixel(x+1, y).a == 0.0: return true
	if y > 0 and img.get_pixel(x, y-1).a == 0.0: return true
	if y < h-1 and img.get_pixel(x, y+1).a == 0.0: return true
	return false

func _add_neighbors(stack: Array, pos: Vector2i):
	stack.push_back(Vector2i(pos.x + 1, pos.y))
	stack.push_back(Vector2i(pos.x - 1, pos.y))
	stack.push_back(Vector2i(pos.x, pos.y + 1))
	stack.push_back(Vector2i(pos.x, pos.y - 1))

func _distance_color(c1: Color, c2: Color) -> float:
	return sqrt(pow(c1.r - c2.r, 2) + pow(c1.g - c2.g, 2) + pow(c1.b - c2.b, 2))

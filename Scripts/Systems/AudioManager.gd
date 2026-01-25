extends Node

# AudioManager.gd
# Global singleton for managing SFX and Music.
# Strategy: Hybrid (File Preference -> Procedural Fallback)

var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 8

var music_player: AudioStreamPlayer
var current_music_key: String = ""

# Database of loaded streams (or placeholders)
var sound_db: Dictionary = {}

# Directory paths
const AUDIO_DIR = "res://Assets/Audio/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keep playing during pause
	
	# Create Music Player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# Create SFX Pool
	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)
	
	print("AudioManager: Ready. Scanning for assets...")
	_scan_and_load()

func _scan_and_load() -> void:
	# 1. Try to load files from disk
	var dir = DirAccess.open(AUDIO_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and (file_name.ends_with(".ogg") or file_name.ends_with(".wav") or file_name.ends_with(".mp3")):
				# Parse filename for base key (e.g., "shoot_1.ogg" -> "shoot")
				# Regex or simple string manipulation
				var full_name = file_name.get_basename() # "shoot_1"
				var key = full_name
				
				# If ends with _number, strip it
				# We assume format: name_1, name_02, etc.
				var regex = RegEx.new()
				regex.compile("([a-zA-Z_]+)(_\\d+)$")
				var match_result = regex.search(full_name)
				if match_result:
					key = match_result.get_string(1) # "shoot" from "shoot_1"
				
				var stream = load(AUDIO_DIR + file_name)
				
				if not sound_db.has(key):
					sound_db[key] = []
				
				sound_db[key].append(stream)
				print("AudioManager: Loaded -> ", key, " (Variant: ", full_name, ")")
				
			file_name = dir.get_next()
	else:
		print("AudioManager: Audio directory not found, creating it...")
		DirAccess.make_dir_recursive_absolute(AUDIO_DIR)
		
	# 2. Procedural Fallback (Removed)
	pass

func play_sfx_loop(key: String, duration: float = 0.0, pitch_scale: float = 1.0, volume_db: float = 0.0) -> AudioStreamPlayer:
	if not sound_db.has(key) or sound_db[key].is_empty():
		return null
		
	var streams: Array = sound_db[key]
	var stream = streams.pick_random()
	if not stream: return null
	
	var player = _get_free_sfx_player()
	if player:
		player.stream = stream
		player.pitch_scale = pitch_scale
		
		# Fade In Logic (Start silent, fade to target)
		player.volume_db = -80.0 
		var tw = create_tween()
		tw.tween_property(player, "volume_db", volume_db, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# Random Start Logic
		var length = stream.get_length()
		var start_pos = 0.0
		var safety_margin = 2.0 # Ensure we don't hit the end of file mid-loop
		
		# If file is longer than the duration needed + margin
		if length > (duration + safety_margin) and duration > 0.0:
			var max_start = length - (duration + safety_margin)
			start_pos = randf_range(0.0, max_start)
			print("Loop segment: ", start_pos, " -> ", start_pos + duration)
		elif length > duration and duration > 0.0:
			# Fallback for shorter files (tight fit)
			var max_start = length - duration
			start_pos = randf_range(0.0, max_start)
			
		player.play(start_pos)
		
		# Optional: If you want it to auto-stop after duration
		# We can return the player and let the caller handle stoppage, 
		# OR use a timer here. For now, returning player is cleaner.
		return player
		
	return null

func play_sfx(key: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not sound_db.has(key) or sound_db[key].is_empty():
		# Silent fail in prod
		if OS.is_debug_build():
			print_rich("[color=yellow][Audio Missing][/color] " + key)
		return
	
	# Pick random variant
	var streams: Array = sound_db[key]
	var stream = streams.pick_random()
	
	if not stream: return
	
	# Find free player
	var player = _get_free_sfx_player()
	if player:
		player.stream = stream
		player.pitch_scale = pitch_scale
		
		# Add slight volume variance (+/- 1.5 db) to prevent "machine gun" fatigue
		var vol_variance = randf_range(-1.5, 1.5)
		player.volume_db = volume_db + vol_variance
		
		player.play()

func play_music(key: String, _crossfade: float = 1.0) -> void:
	if current_music_key == key: return
	
	if sound_db.has(key) and not sound_db[key].is_empty():
		# Music usually doesn't have variations, pick first
		music_player.stream = sound_db[key][0]
		music_player.play()
		current_music_key = key
	else:
		pass

func play_sfx_random_clip(key: String, length_of_clip: float = 0.5, max_concurrent: int = 5, volume_db: float = 0.0) -> void:
	if not sound_db.has(key) or sound_db[key].is_empty():
		return
		
	# Concurrency Check
	if _get_active_count(key) >= max_concurrent:
		return # Too many playing, skip
		
	var streams: Array = sound_db[key]
	var stream = streams.pick_random()
	if not stream: return
	
	var player = _get_free_sfx_player()
	if player:
		player.stream = stream
		player.pitch_scale = randf_range(0.9, 1.1)
		player.volume_db = volume_db
		
		# Metadata for counting
		player.set_meta("current_key", key)
		
		# Pick Random Start
		var full_len = stream.get_length()
		var start_pos = 0.0
		if full_len > length_of_clip:
			start_pos = randf_range(0.0, full_len - length_of_clip)
			
		player.play(start_pos)
		
		# Auto Stop after clip length
		get_tree().create_timer(length_of_clip).timeout.connect(func():
			if player.playing and player.get_meta("current_key") == key:
				# Fade out quick then stop
				var tw = create_tween()
				tw.tween_property(player, "volume_db", -80.0, 0.1)
				tw.tween_callback(player.stop)
				tw.tween_callback(func(): player.set_meta("current_key", ""))
		)

func _get_active_count(key: String) -> int:
	var count = 0
	for p in sfx_players:
		if p.playing and p.has_meta("current_key") and p.get_meta("current_key") == key:
			count += 1
	return count

func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

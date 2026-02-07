extends Node2D

@export var damage: int = 35
@export var max_bounces: int = 4
@export var bounce_range: float = 500.0

var hit_enemies: Array = [] 
var shooter_player: Node2D = null
var last_position: Vector2 = Vector2.ZERO  # Cache position in case enemy dies

func setup(start_pos: Vector2, first_target: Node2D) -> void:
	# Validate first target
	if not is_instance_valid(first_target):
		queue_free()
		return
	
	# Cache position before damaging
	var target_pos = first_target.global_position
	
	# 1. Visual Beam from Player to First Target
	create_lightning_arc(start_pos, target_pos)
	
	# 2. Damage First Target
	zap_enemy(first_target)
	
	# 3. Start Chain (use cached position in case enemy died from damage)
	chain_to_next(target_pos, max_bounces)
	
	# 4. Auto-cleanup after visuals fade
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(self):
		queue_free()

func zap_enemy(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
		
	hit_enemies.append(enemy)
	
	# Play Zap Sound per hit
	AudioManager.play_sfx("lightning_zap", 1.0 + randf_range(-0.1, 0.1))
	
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		
	if shooter_player and is_instance_valid(shooter_player) and shooter_player.has_method("add_ultimate_charge"):
		shooter_player.add_ultimate_charge(5.0) # 5 charge per hit chain

# Changed: now takes position instead of Node2D to avoid accessing freed instance
func chain_to_next(from_pos: Vector2, bounces_left: int) -> void:
	if bounces_left <= 0: return
	
	var nearest = find_nearest_enemy(from_pos)
	if nearest and is_instance_valid(nearest):
		# Cache position BEFORE damaging (in case zap kills it)
		var nearest_pos = nearest.global_position
		
		# Visuals
		create_lightning_arc(from_pos, nearest_pos)
		
		# Delay for "Traveling" feel (Visual + Audio stagger)
		await get_tree().create_timer(0.1).timeout
		
		# Safety check after await - this node might be freed
		if not is_instance_valid(self):
			return
		
		# Damage (might kill the enemy)
		zap_enemy(nearest)
		
		# Recurse using cached position (safe even if enemy died)
		chain_to_next(nearest_pos, bounces_left - 1)

func find_nearest_enemy(from_pos: Vector2) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var min_dist: float = bounce_range
	
	for enemy in enemies:
		if enemy in hit_enemies: continue
		if not is_instance_valid(enemy): continue 
		
		var dist = from_pos.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy
			
	return nearest



func create_lightning_arc(start: Vector2, end: Vector2) -> void:
	var line = Line2D.new()
	line.width = 4.0 # Thicker
	line.default_color = Color(0.6, 0.8, 1.0, 1.0) # Bright Blue
	line.texture_mode = Line2D.LINE_TEXTURE_NONE
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	# Generate jagged points
	var points = []
	points.append(start)
	
	var segments = 8
	var dir = end - start
	var segment_vec = dir / segments
	
	for i in range(1, segments):
		var base_point = start + (segment_vec * i)
		var jitter = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		points.append(base_point + jitter)
		
	points.append(end)
	
	line.points = PackedVector2Array(points)
	add_child(line) 
	
	# Flash Animation
	var tw = create_tween()
	tw.tween_property(line, "width", 8.0, 0.05).from(2.0) # Flash thick
	tw.tween_property(line, "width", 0.0, 0.2) # Fade out quickly
	tw.tween_callback(line.queue_free)

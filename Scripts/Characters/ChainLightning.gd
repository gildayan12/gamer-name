extends Node2D

@export var damage: int = 35
@export var max_bounces: int = 4
@export var bounce_range: float = 500.0

var hit_enemies: Array = [] 

func setup(start_pos: Vector2, first_target: Node2D) -> void:
	# 1. Visual Beam from Player to First Target
	create_lightning_arc(start_pos, first_target.global_position)
	
	# 2. Damage First Target
	zap_enemy(first_target)
	
	# 3. Start Chain
	chain_to_next(first_target, max_bounces)
	
	# 4. Auto-cleanup after visuals fade
	await get_tree().create_timer(1.0).timeout
	queue_free()

func chain_to_next(current_target: Node2D, bounces_left: int) -> void:
	if bounces_left <= 0: return
	
	var nearest = find_nearest_enemy(current_target.global_position)
	if nearest:
		# Visuals
		create_lightning_arc(current_target.global_position, nearest.global_position)
		
		# Damage
		zap_enemy(nearest)
		
		# Recurse Instantly
		chain_to_next(nearest, bounces_left - 1)

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

func zap_enemy(enemy: Node2D) -> void:
	hit_enemies.append(enemy)
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

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

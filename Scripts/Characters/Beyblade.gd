extends Area2D

@export var duration: float = 4.0
@export var tick_rate: float = 0.1 # Damage every 0.1s

var tick_timer: float = 0.0
var inner_radius: float = 100.0
var max_radius: float = 160.0

var shooter_player: Node2D = null

func _ready() -> void:
	# Hit Enemies (Layer 3)
	set_collision_mask_value(3, true)
	
	# Spin animation (simple visual rotation)
	var tw = create_tween().set_loops()
	tw.tween_property(self, "rotation_degrees", 360.0, 0.2).as_relative()
	
	await get_tree().create_timer(duration).timeout
	queue_free()

func _process(delta: float) -> void:
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		process_hits()
	
	queue_redraw()

func process_hits() -> void:
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			var dist = global_position.distance_to(body.global_position)
			
			if dist > inner_radius:
				# EDGE ZONE (> 100)
				# Knockback + Base Damage
				if body.has_method("take_damage"):
					body.take_damage(10)
				if body.has_method("apply_knockback"):
					var dir = (body.global_position - global_position).normalized()
					body.apply_knockback(dir * 500.0) # Medium push
					
			else:
				# INNER ZONE (<= 100)
				# 80% Slow + Scaled Damage
				# Map dist 0..100 to Damage 50..20
				var t = dist / inner_radius # 0.0 (center) to 1.0 (edge)
				var damage = lerp(50.0, 20.0, t)
				
				if body.has_method("take_damage"):
					body.take_damage(int(damage))
				if body.has_method("apply_slow"):
					body.apply_slow(0.2, 0.2) # 20% speed (80% slow) for 0.2s (refreshes)

func _draw() -> void:
	# Visual Debug
	draw_circle(Vector2.ZERO, inner_radius, Color(1.0, 0.2, 0.2, 0.3)) # Inner Red
	draw_arc(Vector2.ZERO, max_radius, 0, TAU, 32, Color(1.0, 0.5, 0.0, 0.8), 4.0) # Outer Ring

extends Area2D

@export var max_radius: float = 150.0
@export var damage: int = 10
@export var push_force: float = 600.0
@export var duration: float = 0.4

var current_radius: float = 0.0
var hit_enemies: Array = [] # Keep track to hit only once

func _ready() -> void:
	# Hit Enemies (Layer 3)
	set_collision_mask_value(3, true)
	
	# Start small
	scale = Vector2.ZERO

	
	# Create tween for expansion
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_method(queue_redraw_circle, 0.0, max_radius, duration)
	
	# Auto-destroy
	await get_tree().create_timer(duration).timeout
	queue_free()

func queue_redraw_circle(radius: float) -> void:
	current_radius = radius
	queue_redraw()

func _draw() -> void:
	# Draw expanding ring
	draw_circle(Vector2.ZERO, current_radius, Color(1.0, 0.8, 0.2, 0.3)) # Inner fill
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 64, Color(1.0, 0.6, 0.0, 0.8), 4.0) # Outer rim

func _process(delta: float) -> void:
	# Check for overlaps manually
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy") and not body in hit_enemies:
			hit_enemies.append(body)
			
			if body.has_method("take_damage"):
				body.take_damage(damage)
			
			if body.has_method("apply_knockback"):
				var dir = (body.global_position - global_position).normalized()
				body.apply_knockback(dir * push_force)
				print("Shockwave hit enemy!")

func _on_body_entered(body: Node2D) -> void:
	# Backup method, but _process handles it
	pass

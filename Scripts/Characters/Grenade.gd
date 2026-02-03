extends Area2D

@export var speed: float = 400.0
@export var damage: int = 50
@export var fuse_time: float = 2.0
@export var blast_radius: float = 180.0 # Increased from 100

var direction: Vector2 = Vector2.RIGHT

var shooter_player: Node2D = null

# Bounce Physics (Fake 3D)
var z_height: float = 0.0 # Vertical Height (Visual only)
var z_velocity: float = 300.0 # Initial Upward Throw
var z_gravity: float = 980.0
var bounce_damp: float = 0.5 # Energy lost on bounce

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Start fuse timer
	var timer = get_tree().create_timer(fuse_time)
	timer.timeout.connect(explode)
	
	# Randomize initial toss slightly
	z_velocity = randf_range(250.0, 350.0)

func _physics_process(delta: float) -> void:
	# 1. Horizontal Movement (Friction applies only on ground)
	var friction = 0.0
	if z_height <= 0.0:
		friction = 400.0 # High friction on ground
	
	speed = move_toward(speed, 0, friction * delta)
	position += direction * speed * delta
	
	# 2. Vertical Movement (Fake Z)
	z_velocity -= z_gravity * delta
	z_height += z_velocity * delta
	
	# 3. Ground Collision (Bounce)
	if z_height <= 0.0:
		z_height = 0.0
		
		# If falling fast enough, bounce
		if z_velocity < -50.0:
			z_velocity = -z_velocity * bounce_damp
			
			# Check force for audio type
			# Lowered threshold to 60 (from 100) so 2nd bounce is still a "Bounce"
			if abs(z_velocity) > 60.0:
				AudioManager.play_sfx("grenade_bounce", 0.8 + randf() * 0.4, 8.0) # +8dB Volume
			else:
				# Soft bounce / Roll
				AudioManager.play_sfx("grenade_roll", 0.9 + randf() * 0.2, 8.0) # +8dB Volume
			
			# Reduce horizontal speed on bounce impact
			speed *= 0.8 
		else:
			# Stop bouncing if too slow
			z_velocity = 0.0
			
	# 4. Visual Update
	if sprite:
		sprite.position.y = -z_height # Up is negative Y in Godot 2D
		
		# Optional: Scale slightly based on height to allow "depth" feel
		var s = 0.3 + (z_height * 0.0005) # Base scale 0.3
		sprite.scale = Vector2(s, s)

func explode() -> void:
	print("BOOM! Grenade exploded.")
	AudioManager.play_sfx("grenade_explode")
	
	# Visual effect (todo)
	
	var hits = 0
	# Damage Area
	var affected_bodies = get_tree().get_nodes_in_group("enemy")
	for enemy in affected_bodies:
		if global_position.distance_to(enemy.global_position) <= blast_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				hits += 1
	
	if hits > 0 and shooter_player and shooter_player.has_method("add_ultimate_charge"):
		var charge_gain = 5.0 * hits # 5 charge per hit
		shooter_player.add_ultimate_charge(charge_gain)
		print("Grenade Hits: ", hits, " Ult Charge: +", charge_gain)
	
	queue_free()

extends Area2D

@export var speed: float = 400.0
@export var damage: int = 50
@export var fuse_time: float = 2.0
@export var blast_radius: float = 180.0 # Increased from 100

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Start fuse timer
	var timer = get_tree().create_timer(fuse_time)
	timer.timeout.connect(explode)

func _physics_process(delta: float) -> void:
	# Grenade slows down (friction)
	speed = move_toward(speed, 0, 200 * delta)
	position += direction * speed * delta

func explode() -> void:
	print("BOOM! Grenade exploded.")
	# Visual effect (todo)
	
	# Damage Area
	var affected_bodies = get_tree().get_nodes_in_group("enemy")
	for enemy in affected_bodies:
		if global_position.distance_to(enemy.global_position) <= blast_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
	
	queue_free()

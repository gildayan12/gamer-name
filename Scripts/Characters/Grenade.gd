extends Area2D

@export var speed: float = 400.0
@export var damage: int = 50
@export var fuse_time: float = 2.0
@export var blast_radius: float = 180.0 # Increased from 100

var direction: Vector2 = Vector2.RIGHT

var shooter_player: Node2D = null

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

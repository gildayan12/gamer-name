extends Area2D

@export var speed: float = 1200.0
@export var damage: int = 150
@export var blast_radius: float = 200.0

func _ready() -> void:
	# Hit Enemies (Layer 3)
	set_collision_mask_value(3, true)


func _physics_process(delta: float) -> void:
	# Rocket acceleration? For now just constant speed
	position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player": return # Ignore launcher
	
	explode()

func explode() -> void:
	print("KABOOM! Bazooka hit.")
	# Visual effect (todo)
	
	# Damage Area
	var affected_bodies = get_tree().get_nodes_in_group("enemy")
	for enemy in affected_bodies:
		if global_position.distance_to(enemy.global_position) <= blast_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
	
	queue_free()

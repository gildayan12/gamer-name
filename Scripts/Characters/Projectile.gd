extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10
@export var lifetime: float = 2.0
var shooter_player: Node2D

func _ready() -> void:
	# Ignore Player (Layer 2)
	set_collision_mask_value(2, false)
	# Hit Enemies (Layer 3)
	set_collision_mask_value(3, true)
	
	# Destroy bullet after 'lifetime' seconds
	await get_tree().create_timer(lifetime).timeout
	queue_free()
	
	shooter_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"): # Assuming enemies will be in this group
		if body.has_method("take_damage"):
			body.take_damage(damage, "gun")
			if shooter_player and shooter_player.has_method("add_ultimate_charge"):
				print("Bullet Hit! Adding Charge.") # Debug
				shooter_player.add_ultimate_charge(2.5)
		queue_free()
	elif not body.is_in_group("player"):
		# Hit wall/obstacle
		queue_free()

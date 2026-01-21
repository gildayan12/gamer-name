extends Area2D

@export var speed: float = 800.0
@export var damage: int = 15

var shooter_player: Node2D = null

func _ready() -> void:
	# Hit Enemies (Layer 3)
	set_collision_mask_value(3, true)
	
	# Randomize slight angle for "storm" feel
	rotation = randf_range(-0.2, 0.2)
	
	# Auto destroy after 2s (off screen)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Use delta to suppress warning (or prefix with _)
	var _d = delta 
	
	position += Vector2.DOWN.rotated(rotation) * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body.name == "TileMap":
		# Splash effect could go here
		queue_free()

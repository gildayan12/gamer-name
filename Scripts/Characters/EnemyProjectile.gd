extends Area2D

@export var speed: float = 400.0
@export var damage: int = 10

func _ready() -> void:
	# Ignore other enemies
	set_collision_layer_value(4, true) # Enemy Projectile Layer
	set_collision_mask_value(1, true) # World
	set_collision_mask_value(2, true) # Player
	set_collision_mask_value(3, false) # Ignore other enemies
	
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free()
	elif body.name == "TileMap" or body is StaticBody2D:
		queue_free()

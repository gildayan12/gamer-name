extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10
@export var lifetime: float = 2.0

func _ready() -> void:
	# Destroy bullet after 'lifetime' seconds
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"): # Assuming enemies will be in this group
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("player"):
		# Hit wall/obstacle
		queue_free()

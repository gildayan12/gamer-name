extends Area2D

@export var speed: float = 2000.0
@export var damage: int = 500
@export var lifetime: float = 3.0

func _ready() -> void:
	# Hit Enemies (Layer 3)
	set_collision_mask_value(3, true)
	
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	connect("body_entered", _on_body_entered)

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		# NOTE: We DO NOT queue_free() here because it pierces!
	elif body.name != "Player": # Hit wall?
		# queue_free() # Optional: destroy on walls
		pass

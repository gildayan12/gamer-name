extends Area2D

@export var speed: float = 500.0
@export var damage: int = 15
@export var range_dist: float = 600.0
var shooter_player: Node2D

func _ready() -> void:
    # Hit Enemies (Layer 3)
    set_collision_mask_value(3, true)


var distance_traveled: float = 0.0

func _physics_process(delta: float) -> void:
    var move_step = speed * delta
    position += Vector2.RIGHT.rotated(rotation) * move_step
    distance_traveled += move_step
    
    if distance_traveled >= range_dist:
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("enemy"):
        if body.has_method("take_damage"):
            body.take_damage(damage)
            if shooter_player and shooter_player.has_method("add_ultimate_charge"):
                shooter_player.add_ultimate_charge(2.5)
        queue_free() # Destroy on impact (single target)

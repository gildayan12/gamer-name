extends Area2D

@export var speed: float = 450.0   # Was 300
@export var damage: int = 25
@export var turn_speed: float = 4.0 # Was 2.0 (Sharper turns)
@export var lifetime: float = 5.0   # Was 8.0 (Explodes faster)

var target: Node2D
var velocity: Vector2 = Vector2.RIGHT

func _ready() -> void:
	add_to_group("enemy_projectile")
	
	# Hit Player (Layer 2) and World
	set_collision_mask_value(2, true) 

	set_collision_mask_value(1, true)
	
	# Find target (Player)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
		
	# Auto destruction
	await get_tree().create_timer(lifetime).timeout
	explode()

func _physics_process(delta: float) -> void:
	if target:
		var target_dir = (target.global_position - global_position).normalized()
		var current_dir = velocity.normalized()
		
		# Slowly rotate towards target
		var new_dir = current_dir.move_toward(target_dir, turn_speed * delta)
		velocity = new_dir.normalized() * speed
		
		rotation = velocity.angle()
		
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		explode()
	elif body.name != "EnemyBoss": # Don't hit the boss
		explode()

func explode() -> void:
	# Add explosion visual/logic here later
	print("Boss Missile Exploded")
	queue_free()

# Time Freeze Compatibility
var is_frozen: bool = false
var saved_velocity: Vector2

func freeze() -> void:
	if is_frozen: return
	is_frozen = true
	saved_velocity = velocity
	velocity = Vector2.ZERO
	set_physics_process(false)

func unfreeze() -> void:
	if not is_frozen: return
	is_frozen = false
	velocity = saved_velocity
	set_physics_process(true)

extends CharacterBody2D

@export var speed: float = 150.0
@export var max_hp: int = 100
var hp: int = max_hp
var attack_cooldown: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var speed_modifier: float = 1.0

var player: Node2D
var health_bar: ProgressBar


func _ready() -> void:
	add_to_group("enemy")
	
	# Layer 3: Enemy
	collision_layer = 4
	collision_mask = 3 # Player + World

	
	# Simple way to find player without direct references
	# We rely on Player.gd adding itself to group "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	# Create Health Bar
	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_bar.size = Vector2(50, 6)
	health_bar.position = Vector2(-25, -40) # Position above head
	
	# Style the bar
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 0, 0, 0.8) # Red
	health_bar.add_theme_stylebox_override("fill", sb)
	
	add_child(health_bar)


func _physics_process(delta: float) -> void:
	# Attack Cooldown
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	
	# Knockback Decay
	if knockback_velocity.length() > 10.0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	else:
		knockback_velocity = Vector2.ZERO

	if player:
		# Chase logic
		var direction = (player.global_position - global_position).normalized()
		# Combine Chase + Knockback
		velocity = (direction * speed * speed_modifier) + knockback_velocity
		move_and_slide()
		
		# Collision Attack
		if attack_cooldown <= 0.0:
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				var collider = collision.get_collider()
				if collider.is_in_group("player") and collider.has_method("take_damage"):
					var dir = (collider.global_position - global_position).normalized()
					collider.take_damage(10, global_position)
					attack_cooldown = 1.0 # 1 second cooldown
					break
		
		# Face player
		look_at(player.global_position)

func take_damage(amount: int) -> void:
	hp -= amount
	if health_bar:
		health_bar.value = hp
	print("Enemy hit! Damage: ", amount, " HP: ", hp)

	
	if hp <= 0:
		queue_free()

func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force

func apply_slow(amount: float, duration: float) -> void:
	# amount is speed multiplier (e.g., 0.2 for 80% slow)
	speed_modifier = amount
	await get_tree().create_timer(duration).timeout
	speed_modifier = 1.0

# Time Freeze Logic
var is_frozen: bool = false
var saved_velocity: Vector2 = Vector2.ZERO

func freeze() -> void:
	is_frozen = true
	saved_velocity = velocity
	set_physics_process(false)
	# If we had animations, pause them here: $AnimatedSprite.pause()

func unfreeze() -> void:
	is_frozen = false
	velocity = saved_velocity
	set_physics_process(true)
	# $AnimatedSprite.play()

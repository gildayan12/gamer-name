extends Area2D

@export var damage: int = 35
var is_swinging: bool = false

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Hit Enemies (Layer 3)
	set_collision_mask_value(3, true)
	collision.disabled = true # Safe state

func swing() -> void:
	if is_swinging: return
	is_swinging = true
	collision.disabled = false
	
	# Play swing animation
	anim.play("swing")
	AudioManager.play_sfx("swing", 1.0, 0.0, 0.1) # 10% Pitch Var
	await anim.animation_finished
	
	collision.disabled = true
	is_swinging = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage, "sword")
			# Find player to credit ult charge
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("add_ultimate_charge"):
				player.add_ultimate_charge(3.0)

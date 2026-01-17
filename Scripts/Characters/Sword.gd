extends Area2D

@export var damage: int = 35
var is_swinging: bool = false

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision.disabled = true # Safe state

func swing() -> void:
	if is_swinging: return
	is_swinging = true
	collision.disabled = false
	
	# Play swing animation
	anim.play("swing")
	await anim.animation_finished
	
	collision.disabled = true
	is_swinging = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

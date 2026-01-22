extends Area2D

@export var heal_amount: int = 20
@export var despawn_time: float = 15.0
@export var blink_duration: float = 5.0

@onready var despawn_timer: Timer = $DespawnTimer
@onready var visual_node: Node2D = $Visuals

func _ready():
	# Connect overlap signal
	body_entered.connect(_on_body_entered)
	
	# Setup timer
	despawn_timer.wait_time = despawn_time
	despawn_timer.one_shot = true
	despawn_timer.timeout.connect(_on_despawn_timeout)
	despawn_timer.start()

func _process(delta):
	var time_left = despawn_timer.time_left
	
	# Blinking effect in the last few seconds
	if time_left < blink_duration:
		# Blink speed increases as time runs out
		var blink_speed = 10.0 if time_left < 2.0 else 5.0
		var alpha = 0.5 + 0.5 * sin(time_left * blink_speed)
		visual_node.modulate.a = alpha

func _on_body_entered(body):
	print("Vial Collision with: ", body.name)
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("heal"):
			print("Healing Player!")
			body.heal(heal_amount)
			# Optional: Play sound effect here
			queue_free()

func _on_despawn_timeout():
	queue_free()

extends CharacterBody2D

@export var speed: float = 150.0

var player: Node2D

func _ready() -> void:
	add_to_group("enemy")
	
	# Simple way to find player without direct references
	# We rely on Player.gd adding itself to group "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if player:
		# Chase logic
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		# Face player
		look_at(player.global_position)

func take_damage(amount: int) -> void:
	# Todo: Add health variable, for now just die instantly or debug
	print("Enemy hit! Damage: ", amount)
	queue_free() # Die instantly for prototype verification

extends CharacterBody2D

@onready var player_model: Node3D = %PlayerModel

const SPEED = 600.0

func _physics_process(_delta: float) -> void:
	# 1. Standard 2D Movement
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		velocity = direction * SPEED
		print("Moving! Velocity: ", velocity)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	move_and_slide()
	
	# 2. Hybrid Rotation Logic
	# Calculate the direction from Player(2D) to Mouse(2D)
	var mouse_pos = get_global_mouse_position()
	var aim_dir = (mouse_pos - global_position).normalized()
	
	# Convert 2D Angle (radians) to 3D Rotation
	# Godot 2D: Right is 0, Down is PI/2
	# Godot 3D: Right is -X (depends on camera), Back is +Z
	# We want the 3D model to rotate around its Y axis.
	
	# Calculate the angle. atan2(y, x) gives the angle from the X axis.
	var angle_2d = aim_dir.angle()
	
	# Apply to 3D Model. 
	# Note: We might need to offset this by 90 degrees (-PI/2) depending on the model's forward face.
	# Assuming the model faces -Z (Godot Standard Forward):
	# 2D Right (0) -> 3D Right (+X).
	# This mapping often requires a -sign or offset.
	# Let's try direct mapping first, flipping Y because 3D Y is Up, 2D Y is Down.
	
	if player_model:
		# We rotate the model around the Y axis.
		# User reported opposite direction, so we add PI (180 degrees)
		player_model.rotation.y = -angle_2d + (PI / 2) + PI

extends "res://Scripts/Characters/Enemy.gd"

func _ready() -> void:
	speed = 80.0 # Much slower
	max_hp = 300 # Tanky
	hp = max_hp
	super._ready() # Call base class for grouping and layers
	
	# Scale visuals
	if has_node("visuals"):
		$visuals.scale = Vector2(2.0, 2.0)
	elif has_node("Sprite2D"):
		$Sprite2D.scale = Vector2(0.6, 0.6) # Standard icon is 128px, 0.6 is ~76px
		
	if health_bar:
		health_bar.size = Vector2(100, 8)
		health_bar.position = Vector2(-50, -60) # Higher for the big tank


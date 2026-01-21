extends Node2D

@onready var label: Label = $Label

func setup(value: int, type: String = "Normal") -> void:
	if not label: await ready
	
	label.text = str(value)
	
	# Color Coding
	match type:
		"Critical":
			label.modulate = Color(1.0, 0.0, 0.0) # Red
			label.scale = Vector2(1.5, 1.5)
		"Heal":
			label.modulate = Color(0.0, 1.0, 0.0) # Green
		"Normal":
			label.modulate = Color(1.0, 1.0, 1.0) # White
			
	# Animation (Tween)
	var tw = create_tween()
	tw.set_parallel(true)
	
	# Float Up
	tw.tween_property(self, "position", position + Vector2(0, -50), 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Fade Out
	tw.tween_property(self, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Cleanup
	await tw.finished
	queue_free()

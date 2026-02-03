extends CharacterBody2D

@export var max_hp: int = 60
@export var shoot_cooldown: float = 2.0
@export var detection_range: float = 600.0

var hp: int = max_hp
var cooldown_timer: float = 0.0
var player: Node2D
var health_bar: ProgressBar
var aim_line: Line2D

var startup_timer: float = 2.0



const PROJECTILE_SCENE = preload("res://Scenes/Characters/EnemyProjectile.tscn")
const DAMAGE_NUMBER_SCENE = preload("res://Scenes/UI/DamageNumber.tscn")
const HIT_PARTICLES_SCENE = preload("res://Scenes/Characters/HitParticles.tscn")
const VIAL_SCENE = preload("res://Scenes/Items/HealthVial.tscn")

@export var drop_chance: float = 0.05

func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4 # Enemy Layer
	collision_mask = 3 # Player + World
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	# Create Health Bar
	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_bar.size = Vector2(40, 5)
	health_bar.position = Vector2(-20, -35)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 0, 0, 0.8)
	health_bar.add_theme_stylebox_override("fill", sb)
	add_child(health_bar)
	
	# Create Aim Line
	aim_line = Line2D.new()
	aim_line.width = 1.0
	aim_line.default_color = Color(1, 0, 0, 0.3) # Faint red
	aim_line.add_point(Vector2.ZERO)
	aim_line.add_point(Vector2(detection_range, 0))
	add_child(aim_line)
	aim_line.visible = false


func _physics_process(delta: float) -> void:
	if is_frozen: return
	
	if startup_timer > 0:
		startup_timer -= delta
		return
	
	if cooldown_timer > 0:

		cooldown_timer -= delta
		
	if player:
		var dist = global_position.distance_to(player.global_position)
		look_at(player.global_position)
		
		# Telegraphing: Show laser if close to firing
		if dist < detection_range:
			aim_line.visible = true
			# Pulse laser as it gets ready
			var alpha = 0.1 + (1.0 - (cooldown_timer / shoot_cooldown)) * 0.4
			aim_line.default_color.a = clamp(alpha, 0.1, 0.5)
		else:
			aim_line.visible = false
			
		if dist < detection_range and cooldown_timer <= 0:
			shoot()


func shoot() -> void:
	cooldown_timer = shoot_cooldown
	var proj = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position
	proj.global_rotation = global_rotation
	print("Turret fired at player!")

func take_damage(amount: int, source: String = "gun") -> void:
	hp -= amount
	if health_bar:
		health_bar.value = hp
		
	# Visuals
	spawn_damage_number(amount)
	flash_hit()
	spawn_hit_particles()
	
	# Turrets are metal -> Heavy Sound
	AudioManager.play_sfx("enemy_hit_heavy", 0.9 + randf() * 0.2)
	
	if hp <= 0:
		# Drop Health Vial
		if randf() < drop_chance:
			if VIAL_SCENE:
				var vial = VIAL_SCENE.instantiate()
				get_parent().add_child(vial)
				vial.global_position = global_position
				
		queue_free()

func spawn_damage_number(amount: int) -> void:
	if not DAMAGE_NUMBER_SCENE: return
	var dn = DAMAGE_NUMBER_SCENE.instantiate()
	dn.global_position = global_position
	get_tree().current_scene.add_child(dn)
	dn.setup(amount)

func flash_hit() -> void:
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		if sprite.material:
			var tw = create_tween()
			sprite.material.set_shader_parameter("flash_modifier", 1.0)
			tw.tween_method(func(v): sprite.material.set_shader_parameter("flash_modifier", v), 1.0, 0.0, 0.2)
			
func spawn_hit_particles() -> void:
	if not HIT_PARTICLES_SCENE: return
	
	var p = HIT_PARTICLES_SCENE.instantiate()
	p.global_position = global_position
	get_tree().current_scene.add_child(p)

# Compatibility with Time Freeze
var is_frozen: bool = false
func freeze() -> void:
	is_frozen = true
	set_physics_process(false)

func unfreeze() -> void:
	is_frozen = false
	set_physics_process(true)

extends Node2D

enum NucleusType { PROTON, NEUTRON }

@export var nucleus_type: NucleusType = NucleusType.PROTON

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Oscillation properties
var oscillation_offset: Vector2 = Vector2.ZERO
var oscillation_speed: Vector2
var oscillation_amplitude := 3.0  # pixels
var time_offset: float

func _ready():
	# Ensure sprite is centered (pivot at center, not top-left)
	sprite.centered = true
	
	# Random oscillation parameters for each nucleus
	oscillation_speed = Vector2(
		randf_range(0.5, 1.5),  # X speed
		randf_range(0.5, 1.5)   # Y speed
	)
	time_offset = randf() * TAU  # Random start phase
	
	# Play spawn animation first
	sprite.play("spawn")
	sprite.animation_finished.connect(_on_spawn_finished)

func _process(delta):
	# Gentle sinusoidal oscillation applied to SPRITE position, not node position
	var time = Time.get_ticks_msec() / 1000.0 + time_offset
	oscillation_offset = Vector2(
		sin(time * oscillation_speed.x) * oscillation_amplitude,
		cos(time * oscillation_speed.y) * oscillation_amplitude
	)
	
	# Apply oscillation to sprite position (offset from node's position)
	sprite.position = oscillation_offset

func _on_spawn_finished():
	if nucleus_type == NucleusType.PROTON:
		sprite.play("proton")
	else:
		sprite.play("neutron")

func set_type(type: NucleusType):
	nucleus_type = type

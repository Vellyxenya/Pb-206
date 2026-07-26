extends Area2D

@export var attraction_strength: float = 15000.0
@export var min_scale: float = 0.7
@export var max_scale: float = 1.4

func _ready() -> void:
	# Randomize scale and rotation
	var random_scale = randf_range(min_scale, max_scale)
	scale = Vector2(random_scale, random_scale)
	rotation = randf() * TAU

func _physics_process(_delta):
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("player"):
			if true:
				var direction_towards = body.global_position.direction_to(global_position)
				body.apply_external_force(direction_towards * attraction_strength)

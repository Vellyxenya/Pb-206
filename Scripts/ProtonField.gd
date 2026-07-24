extends Area2D

@export var repulsion_strength: float = 15000.0

func _physics_process(_delta):
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("player"):
			# Only affect charged atoms (positive charge is repelled by proton field)
			if body.has_method("get_charge") and body.get_charge() > 0:
				var direction_away = global_position.direction_to(body.global_position)
				body.apply_external_force(direction_away * repulsion_strength)

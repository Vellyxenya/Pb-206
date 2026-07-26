extends Node2D

@onready var atom: RigidBody2D = $Atom
@onready var boost_particles: GPUParticles2D = $GPUParticles2D

func _input(event: InputEvent) -> void:
	if atom == null:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_Y and atom.has_method("teleport_towards"):
		atom.teleport_towards(get_global_mouse_position(), 100.0)

func _physics_process(_delta):
	if atom != null and atom.has_method("drive_towards"):
		atom.drive_towards(get_global_mouse_position())

func _update_boost_particles() -> void:
	"""Update boost particle emission based on atom state"""
	if boost_particles == null or atom == null:
		return
	
	# Enable/disable particles based on boost state
	var should_emit = atom.is_boosting and atom.linear_velocity.length() > 10.0
	boost_particles.emitting = should_emit
	
	if should_emit:
		# Position particles at atom location
		boost_particles.global_position = atom.global_position
		
		# Calculate opposite direction of movement
		var velocity_direction = atom.linear_velocity.normalized()
		var opposite_angle = velocity_direction.angle() + PI
		
		# Set particle emission direction (opposite to movement)
		var particle_material = boost_particles.process_material as ParticleProcessMaterial
		if particle_material != null:
			# Convert angle to Vector3 for the particle material
			particle_material.direction = Vector3(cos(opposite_angle), sin(opposite_angle), 0)

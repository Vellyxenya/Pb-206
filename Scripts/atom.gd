extends RigidBody2D

const NucleusScene = preload("res://Scenes/nucleus.tscn")

@export var isotope_key: String = "U-238"
@export var acceleration_force: float = 2600.0
@export var movement_damping: float = 1.1
@export var mouse_deadzone: float = 2.0
@export var collider_padding: float = 18.0

var mass_number: int
var disk_radius: float
var isotope_name: String
var proton_tint: Color = Color(0.95, 0.25, 0.25)

func _ready():
	gravity_scale = 0.0
	lock_rotation = true
	linear_damp = movement_damping

	load_isotope_data()
	mass = max(1.0, float(mass_number - 200))
	spawn_nuclei()

func drive_towards(world_target: Vector2) -> void:
	var to_target = world_target - global_position
	if to_target.length_squared() > mouse_deadzone * mouse_deadzone:
		apply_central_force(to_target.normalized() * acceleration_force)

func load_isotope_data():
	var data = IsotopeData.get_isotope(isotope_key)
	if data.is_empty():
		push_error("Failed to load isotope: " + isotope_key)
		return
	
	isotope_name = data.name
	mass_number = data.mass_number
	disk_radius = data.disk_radius
	proton_tint = IsotopeData.get_proton_tint(isotope_key)
	
	print("Loaded isotope: ", isotope_name, " (", mass_number, ")")

func spawn_nuclei():
	var proton_count = IsotopeData.get_proton_count(isotope_key)
	var neutron_count = IsotopeData.get_neutron_count(isotope_key)
	var nucleus_count = proton_count + neutron_count - 200  # mass - 200
	var total_nucleons = proton_count + neutron_count
	if nucleus_count <= 0 or total_nucleons <= 0:
		push_error("Invalid isotope counts for " + isotope_key)
		return

	var visible_protons = int(round(float(nucleus_count) * float(proton_count) / float(total_nucleons)))
	var visible_neutrons = nucleus_count - visible_protons
	
	print("Spawning ", nucleus_count, " nuclei: ", visible_protons, " proton visuals + ", visible_neutrons, " neutron visuals")
	
	# Get hexagonal grid positions
	var hex_positions = HexGrid.get_hex_positions(nucleus_count, Vector2.ZERO)
	_setup_collision_shape(hex_positions)

	# Build a mixed type list, then shuffle so protons/neutrons are spatially interleaved.
	const PROTON_TYPE := 0
	const NEUTRON_TYPE := 1
	var nucleus_types: Array[int] = []
	for i in range(visible_protons):
		nucleus_types.append(PROTON_TYPE)
	for i in range(visible_neutrons):
		nucleus_types.append(NEUTRON_TYPE)
	nucleus_types.shuffle()

	for i in range(nucleus_count):
		var nucleus = NucleusScene.instantiate()
		nucleus.position = hex_positions[i]
		nucleus.set_type(nucleus_types[i], proton_tint)
		add_child(nucleus)

func _setup_collision_shape(hex_positions: Array[Vector2]) -> void:
	var max_dist := 0.0
	for pos in hex_positions:
		max_dist = max(max_dist, pos.length())

	var radius = max_dist + collider_padding
	var collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)

	var circle = collision_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		collision_shape.shape = circle

	circle.radius = radius

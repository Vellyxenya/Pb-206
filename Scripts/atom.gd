extends RigidBody2D

const NucleusScene = preload("res://Scenes/nucleus.tscn")

signal phase_timer_finished

@export var isotope_key: String = "U-238"
@export var acceleration_force: float = 2600.0
@export var movement_damping: float = 1.1
@export var mouse_deadzone: float = 12.0
@export var collider_padding: float = 18.0

var mass_number: int
var external_force: Vector2 = Vector2.ZERO
var phase_time_left: float = 0.0
var phase_time_total: float = 0.0
var phase_active: bool = false
var isotope_name: String = ""
var disk_radius: float = 0.0
var proton_tint: Color = Color.WHITE


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var force_to_apply = external_force
	if force_to_apply != Vector2.ZERO:
		state.apply_central_force(force_to_apply)
		external_force = Vector2.ZERO


func _ready():
	gravity_scale = 0.0
	lock_rotation = true
	linear_damp = movement_damping

	load_isotope_data()
	mass = max(1.0, float(mass_number - 200))
	spawn_nuclei()

func apply_external_force(force: Vector2):
	external_force += force

func drive_towards(world_target: Vector2) -> void:
	tick_phase_timer(get_physics_process_delta_time())
	
	var to_target = world_target - global_position
	if to_target.length_squared() > mouse_deadzone * mouse_deadzone:
		apply_central_force(to_target.normalized() * acceleration_force)

func _input(event: InputEvent) -> void:
	# DEBUG: Press 'T' to reduce timer by 10 seconds for quick testing
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		phase_time_left = max(0.0, phase_time_left - 10.0)
		print("DEBUG: Timer reduced by 10s. Remaining: ", snapped(phase_time_left, 0.1), "s")

func teleport_towards(world_target: Vector2, distance: float) -> void:
	var to_target = world_target - global_position
	if to_target.length_squared() <= 0.0001:
		return

	global_position += to_target.normalized() * distance
	linear_velocity = Vector2.ZERO

func tick_phase_timer(delta: float) -> void:
	if not phase_active:
		return

	phase_time_left -= delta
	if phase_time_left <= 0.0:
		phase_time_left = 0.0
		phase_active = false
		on_phase_timer_finished()

func on_phase_timer_finished() -> void:
	print("Phase timer finished for ", isotope_name)
	phase_timer_finished.emit()

func on_phase_completed() -> void:
	print("Phase completed successfully for ", isotope_name)

func play_destroy_animation() -> void:
	var nuclei = _get_nucleus_nodes()
	if nuclei.is_empty():
		return

	var destroy_duration := 0.35
	for nucleus in nuclei:
		if nucleus.has_method("play_destroy_animation"):
			nucleus.play_destroy_animation()
		if nucleus.has_method("get_destroy_duration"):
			destroy_duration = max(destroy_duration, float(nucleus.get_destroy_duration()))

	await get_tree().create_timer(destroy_duration).timeout

func reset_phase_visuals() -> void:
	_clear_nucleus_nodes()
	spawn_nuclei()

func get_phase_time_left() -> float:
	return phase_time_left

func get_phase_time_total() -> float:
	return phase_time_total

func is_phase_active() -> bool:
	return phase_active

func load_isotope_data():
	var data = IsotopeData.get_isotope(isotope_key)
	if data.is_empty():
		push_error("Failed to load isotope: " + isotope_key)
		return
	
	isotope_name = data.name
	mass_number = data.mass_number
	disk_radius = data.disk_radius
	proton_tint = IsotopeData.get_proton_tint(isotope_key)
	mass = max(1.0, float(mass_number - 200))
	
	var timer_range = data.timer_range
	phase_time_total = randf_range(float(timer_range[0]), float(timer_range[1]))
	phase_time_left = phase_time_total
	phase_active = true
	
	print("Loaded isotope: ", isotope_name, " (", mass_number, ")")
	print("Phase timer started: ", snapped(phase_time_left, 0.1), "s")

func _get_nucleus_nodes() -> Array[Node]:
	var nuclei: Array[Node] = []
	for child in get_children():
		if child.is_in_group("nucleus_visual"):
			nuclei.append(child)
	return nuclei

func _clear_nucleus_nodes() -> void:
	for nucleus in _get_nucleus_nodes():
		nucleus.free()

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

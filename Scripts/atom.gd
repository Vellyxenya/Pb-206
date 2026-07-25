extends RigidBody2D

const NucleusScene = preload("res://Scenes/nucleus.tscn")

signal phase_timer_finished
signal cheat_decay_triggered

@export var isotope_key: String = "U-238"
@export var acceleration_force: float = 7400.0
@export var movement_damping: float = 1.1
@export var mouse_deadzone: float = 20.0
@export var collider_padding: float = -18.0
@export var electron_shell_spacing: float = 28.0
@export var electron_orbit_speed: float = 1.2
@export var max_energy: float = 100.0
@export var boost_speed_multiplier: float = 3.0
@export var energy_drain_rate: float = 20.0  # Energy drained per second while boosting
@export var energy_regen_rate: float = 2.0  # Energy regenerated per second when not boosting
@export var min_energy_to_boost: float = 1.0  # Minimum energy required to start boosting
@export var boost_transition_speed: float = 7.0  # Speed of boost lerp transition

var mass_number: int
var external_force: Vector2 = Vector2.ZERO
var phase_time_left: float = 0.0
var phase_time_total: float = 0.0
var phase_active: bool = false
var isotope_name: String = ""
var disk_radius: float = 0.0
var proton_tint: Color = Color.WHITE
var charge: int = 0  # 0 = neutral, +1 = positively charged (after β-decay)
var collision_radius: float = 0.0  # Stores the atom's collision shape radius
var electrons: Array[Node2D] = []
var electron_angles: Array[float] = []
var electron_radii: Array[float] = []
var orbit_circles: Array[Line2D] = []  # Visual orbit paths
var current_energy: float = 0.0
var energy_bar: ProgressBar = null
var is_boosting: bool = false
var current_speed_multiplier: float = 1.0


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var force_to_apply = external_force
	if force_to_apply != Vector2.ZERO:
		state.apply_central_force(force_to_apply)
		external_force = Vector2.ZERO


func _ready():
	gravity_scale = 0.0
	lock_rotation = true
	linear_damp = movement_damping
	
	# Start with full energy
	current_energy = max_energy

	load_isotope_data()
	mass = max(1.0, float(mass_number - 200))
	spawn_nuclei()
	_update_charge_visual()  # Initialize visual state
	_setup_energy_bar()  # Create energy bar

func _process(delta: float) -> void:
	_update_electron_orbits(delta)
	_handle_boost_input(delta)

func apply_external_force(force: Vector2):
	external_force += force

func drive_towards(world_target: Vector2) -> void:
	tick_phase_timer(get_physics_process_delta_time())
	
	var to_target = world_target - global_position
	if to_target.length_squared() > mouse_deadzone * mouse_deadzone:
		# Apply current speed multiplier to the force
		var boosted_force = acceleration_force * current_speed_multiplier
		apply_central_force(to_target.normalized() * boosted_force)

func _input(event: InputEvent) -> void:
	# DEBUG: Press 'T' to reduce timer by 10 seconds for quick testing
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		phase_time_left = max(0.0, phase_time_left - 10.0)
		print("DEBUG: Timer reduced by 10s. Remaining: ", snapped(phase_time_left, 0.1), "s")
	
	# DEBUG: Press 'D' to instantly decay to next stage (testing purposes)
	if event is InputEventKey and event.pressed and event.keycode == KEY_D:
		phase_time_left = 0.0
		phase_active = false
		cheat_decay_triggered.emit()
		print("DEBUG: Instant decay triggered!")

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

func play_decay_effect(decay_type: String) -> void:
	"""Play visual effect for alpha or beta decay"""
	print("Decay effect: ", decay_type)
	
	if decay_type == "alpha":
		# Alpha decay: eject a visible alpha particle (helium nucleus)
		await _play_alpha_decay_effect()
	elif decay_type == "beta":
		# Beta decay: eject an electron with spark effect
		await _play_beta_decay_effect()
	
	# Wait a moment before transition
	await get_tree().create_timer(0.3).timeout

func _play_alpha_decay_effect() -> void:
	"""Eject an alpha particle (2 protons + 2 neutrons) as a visual cluster"""
	# Create alpha particle container
	var alpha_particle = Node2D.new()
	alpha_particle.name = "AlphaParticle"
	alpha_particle.global_position = global_position
	alpha_particle.z_index = 50
	get_parent().add_child(alpha_particle)
	
	# Create 4 nuclei visuals in a tight cluster (2 protons + 2 neutrons)
	var cluster_positions = [
		Vector2(-6, -6),
		Vector2(6, -6),
		Vector2(-6, 6),
		Vector2(6, 6)
	]
	
	for i in range(4):
		var nucleus_visual = Polygon2D.new()
		nucleus_visual.position = cluster_positions[i]
		
		# 2 protons (red), 2 neutrons (blue)
		var is_proton = (i < 2)
		var color = Color(0.95, 0.25, 0.25, 0.9) if is_proton else Color(0.3, 0.5, 0.9, 0.9)
		
		# Create circular polygon
		var circle_points: Array[Vector2] = []
		var radius = 8.0
		for j in range(16):
			var angle = (float(j) / 16.0) * TAU
			circle_points.append(Vector2(cos(angle), sin(angle)) * radius)
		
		nucleus_visual.polygon = circle_points
		nucleus_visual.color = color
		alpha_particle.add_child(nucleus_visual)
	
	# Eject the alpha particle
	var eject_direction = Vector2.RIGHT.rotated(randf() * TAU)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(alpha_particle, "global_position", alpha_particle.global_position + eject_direction * 200, 0.8)
	tween.tween_property(alpha_particle, "modulate:a", 0.0, 0.8)
	tween.tween_property(alpha_particle, "scale", Vector2(0.5, 0.5), 0.8)
	await tween.finished
	
	alpha_particle.queue_free()

func _play_beta_decay_effect() -> void:
	"""Eject an electron with spark/flash effect"""
	# Create flash effect
	var flash = Polygon2D.new()
	flash.name = "BetaFlash"
	flash.global_position = global_position
	flash.z_index = 50
	
	# Create star/spark shape
	var spark_points: Array[Vector2] = []
	for i in range(8):
		var angle = (float(i) / 8.0) * TAU
		var radius = 30.0 if i % 2 == 0 else 10.0
		spark_points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	flash.polygon = spark_points
	flash.color = Color(0.3, 0.7, 1.0, 0.8)  # Bright blue
	get_parent().add_child(flash)
	
	# Create electron particle
	var electron = Polygon2D.new()
	electron.name = "Electron"
	electron.global_position = global_position
	electron.z_index = 51
	
	# Small circle for electron
	var electron_points: Array[Vector2] = []
	for i in range(12):
		var angle = (float(i) / 12.0) * TAU
		electron_points.append(Vector2(cos(angle), sin(angle)) * 6.0)
	
	electron.polygon = electron_points
	electron.color = Color(0.3, 0.7, 1.0, 1.0)
	get_parent().add_child(electron)
	
	# Flash expands and fades quickly
	var flash_tween = create_tween()
	flash_tween.set_parallel(true)
	flash_tween.tween_property(flash, "scale", Vector2(2.0, 2.0), 0.3)
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	
	# Electron shoots out
	var eject_direction = Vector2.RIGHT.rotated(randf() * TAU)
	var electron_tween = create_tween()
	electron_tween.set_parallel(true)
	electron_tween.tween_property(electron, "global_position", electron.global_position + eject_direction * 250, 0.7)
	electron_tween.tween_property(electron, "modulate:a", 0.0, 0.7)
	
	await electron_tween.finished
	
	flash.queue_free()
	electron.queue_free()

func reset_phase_visuals() -> void:
	_clear_nucleus_nodes()
	_clear_electrons()
	_clear_orbit_circles()
	spawn_nuclei()
	# Start with full energy on phase transition
	current_energy = max_energy
	if energy_bar != null:
		energy_bar.value = current_energy
		_update_energy_bar_color()

func get_phase_time_left() -> float:
	return phase_time_left

func get_phase_time_total() -> float:
	return phase_time_total

func is_phase_active() -> bool:
	return phase_active

func _setup_energy_bar() -> void:
	"""Create and configure the energy bar that follows the atom"""
	energy_bar = ProgressBar.new()
	energy_bar.name = "EnergyBar"
	
	# Position below the IsotopeNameLabel
	energy_bar.position = Vector2(-100, -140)
	energy_bar.size = Vector2(200, 20)
	energy_bar.min_value = 0.0
	energy_bar.max_value = max_energy
	energy_bar.value = current_energy
	energy_bar.show_percentage = false
	energy_bar.z_index = 25
	
	# Style the energy bar
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(1.0, 1.0, 0.0, 0.8)  # Start with yellow
	stylebox.set_corner_radius_all(3)
	energy_bar.add_theme_stylebox_override("fill", stylebox)
	
	# Background style
	var bg_stylebox = StyleBoxFlat.new()
	bg_stylebox.bg_color = Color(0.2, 0.2, 0.2, 0.6)
	bg_stylebox.set_corner_radius_all(3)
	energy_bar.add_theme_stylebox_override("background", bg_stylebox)
	
	add_child(energy_bar)

func add_energy(amount: float) -> void:
	"""Add energy to the energy bar"""
	current_energy = min(current_energy + amount, max_energy)
	if energy_bar != null:
		energy_bar.value = current_energy
		_update_energy_bar_color()

func _update_energy_bar_color() -> void:
	"""Update energy bar color based on fill percentage (yellow -> purple gradient)"""
	if energy_bar == null:
		return
	
	var fill_ratio = current_energy / max_energy
	
	# Interpolate from yellow (1, 1, 0) to purple (0.5, 0, 0.8)
	var yellow = Color(1.0, 1.0, 0.0, 0.8)
	var purple = Color(0.5, 0.0, 0.8, 0.8)
	var current_color = yellow.lerp(purple, fill_ratio)
	
	# Update the fill stylebox color
	var stylebox = energy_bar.get_theme_stylebox("fill")
	if stylebox is StyleBoxFlat:
		stylebox.bg_color = current_color

func _handle_boost_input(delta: float) -> void:
	"""Handle boost mechanic with left mouse button"""
	# Check if left mouse button is pressed and we have enough energy
	var wants_to_boost = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var can_boost = current_energy >= min_energy_to_boost
	
	if wants_to_boost and can_boost:
		is_boosting = true
		# Drain energy while boosting
		current_energy = max(0.0, current_energy - energy_drain_rate * delta)
		if energy_bar != null:
			energy_bar.value = current_energy
			_update_energy_bar_color()
	else:
		# Can't boost or button released
		if is_boosting and current_energy <= 0.0:
			is_boosting = false  # Energy depleted
		elif not wants_to_boost:
			is_boosting = false  # Button released
		
		# Regenerate energy when not boosting
		if not is_boosting:
			current_energy = min(max_energy, current_energy + energy_regen_rate * delta)
			if energy_bar != null:
				energy_bar.value = current_energy
				_update_energy_bar_color()
	
	# Smoothly transition speed multiplier
	var target_multiplier = boost_speed_multiplier if is_boosting else 1.0
	current_speed_multiplier = lerp(current_speed_multiplier, target_multiplier, boost_transition_speed * delta)

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
	
	print("Loaded isotope: ", isotope_name, " (", mass_number, "), charge: ", charge)
	print("Phase timer started: ", snapped(phase_time_left, 0.1), "s")
	_update_charge_visual()

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
	
	# Spawn electrons based on visible proton count
	spawn_electrons(visible_protons)

func _setup_collision_shape(hex_positions: Array[Vector2]) -> void:
	var max_dist := 0.0
	for pos in hex_positions:
		max_dist = max(max_dist, pos.length())

	var radius = max_dist + collider_padding
	collision_radius = radius  # Store for electron orbit calculations
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

func get_charge() -> int:
	return charge

func set_charge(new_charge: int) -> void:
	charge = new_charge
	print("Charge set to: ", charge)
	_update_charge_visual()

func _update_charge_visual() -> void:
	# Update the isotope name label
	var name_label = get_node_or_null("IsotopeNameLabel") as Label
	if name_label != null:
		name_label.text = isotope_name
	
	# Update the charge indicator label
	var charge_label = get_node_or_null("ChargeIndicator") as Label
	if charge_label != null:
		if charge > 0:
			charge_label.text = "+"
			charge_label.modulate = Color(1.0, 0.3, 0.3)  # Red for positive
			charge_label.visible = true
		else:
			charge_label.visible = false

func spawn_electrons(electron_count: int) -> void:
	"""Spawn electrons in orbital shells around the atom"""
	_clear_electrons()
	_clear_orbit_circles()
	
	if electron_count <= 0:
		return
	
	# Define electron shell capacities: 2, 8, 8, 18, 18, ...
	var shell_capacities: Array[int] = [2, 8, 8, 18, 18, 32]
	var electrons_remaining = electron_count
	var shell_index = 0
	
	# Base radius is collision radius + 20
	var base_orbit_radius = collision_radius + 40.0
	
	while electrons_remaining > 0 and shell_index < shell_capacities.size():
		var electrons_in_shell = min(electrons_remaining, shell_capacities[shell_index])
		var shell_radius = base_orbit_radius + (shell_index * electron_shell_spacing)
		
		# Create orbit circle for this shell
		_create_orbit_circle(shell_radius)
		
		# Calculate angles for paired electrons
		var pair_count = int(ceil(float(electrons_in_shell) / 2.0))
		var pair_separation = 6.0  # Degrees between paired electrons
		
		# Distribute electron pairs evenly around the shell
		for i in range(electrons_in_shell):
			@warning_ignore("integer_division")
			var pair_index: int = i / 2
			var is_second_in_pair = (i % 2) == 1
			
			# Base angle for this pair
			var base_angle = (TAU * float(pair_index)) / float(pair_count)
			
			# Offset slightly for pairing effect
			var angle_offset = 0.0
			if is_second_in_pair:
				angle_offset = deg_to_rad(pair_separation)
			else:
				angle_offset = -deg_to_rad(pair_separation)
			
			var angle = base_angle + angle_offset
			_spawn_electron(shell_radius, angle)
		
		electrons_remaining -= electrons_in_shell
		shell_index += 1
	
	print("Spawned ", electron_count, " electrons across ", shell_index, " shells")

func _spawn_electron(radius: float, initial_angle: float) -> void:
	"""Create a single electron at the given radius and angle"""
	var electron = Node2D.new()
	electron.z_index = 15  # Draw above nucleus but below UI
	add_child(electron)
	
	# Create visual circle for electron
	var visual = Polygon2D.new()
	var electron_size = 4.0
	var circle_points: PackedVector2Array = []
	var segments = 12
	for i in range(segments):
		var angle = (TAU * float(i)) / float(segments)
		circle_points.append(Vector2(cos(angle), sin(angle)) * electron_size)
	visual.polygon = circle_points
	visual.color = Color(0.3, 0.7, 1.0, 0.9)  # Light blue electron
	electron.add_child(visual)
	
	# Add a glow effect
	var glow = Polygon2D.new()
	var glow_points: PackedVector2Array = []
	for i in range(segments):
		var angle = (TAU * float(i)) / float(segments)
		glow_points.append(Vector2(cos(angle), sin(angle)) * (electron_size * 1.8))
	glow.polygon = glow_points
	glow.color = Color(0.4, 0.8, 1.0, 0.3)  # Semi-transparent glow
	glow.z_index = -1
	electron.add_child(glow)
	
	electrons.append(electron)
	electron_angles.append(initial_angle)
	electron_radii.append(radius)

func _create_orbit_circle(radius: float) -> void:
	"""Create a visual orbit circle at the given radius"""
	var orbit = Line2D.new()
	orbit.z_index = 10  # Below electrons
	orbit.width = 1.0
	orbit.default_color = Color(0.4, 0.6, 0.8, 0.25)  # Semi-transparent blue-gray
	orbit.antialiased = true
	
	# Create circle points
	var segments = 64
	var points: PackedVector2Array = []
	for i in range(segments + 1):
		var angle = (TAU * float(i)) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	orbit.points = points
	
	add_child(orbit)
	orbit_circles.append(orbit)

func _update_electron_orbits(delta: float) -> void:
	"""Update electron positions to orbit around the atom"""
	for i in range(electrons.size()):
		if i >= electron_angles.size() or i >= electron_radii.size():
			continue
		
		# Update angle
		electron_angles[i] += electron_orbit_speed * delta
		if electron_angles[i] > TAU:
			electron_angles[i] -= TAU
		
		# Update position
		var radius = electron_radii[i]
		var angle = electron_angles[i]
		electrons[i].position = Vector2(cos(angle), sin(angle)) * radius

func _clear_electrons() -> void:
	"""Remove all electrons"""
	for electron in electrons:
		if is_instance_valid(electron):
			electron.queue_free()
	electrons.clear()
	electron_angles.clear()
	electron_radii.clear()

func _clear_orbit_circles() -> void:
	"""Remove all orbit circle visuals"""
	for orbit in orbit_circles:
		if is_instance_valid(orbit):
			orbit.queue_free()
	orbit_circles.clear()

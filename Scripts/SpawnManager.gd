extends Node2D

## SpawnManager - Handles dynamic spawning of collectibles, hazards, and goals
## Spawns entities around player based on density targets

# Spawn configuration
@export_group("Goal Settings")
@export var goal_radius: float = 1200.0
@export var min_goal_edge_distance: float = 900.0
@export var max_goal_center_distance: float = 5200.0
@export var goal_area_neutrino_multiplier: float = 1.6  # Extra neutrinos in goal area
@export var goal_area_hazard_count: int = 1  # Neutron fields near goal

@export_group("Spawn Area")
@export var spawn_check_interval: float = 0.5  # How often to check spawn needs
@export var spawn_radius: float = 3000.0  # Spawn items within this radius of player
@export var despawn_radius: float = 4000.0  # Despawn items beyond this radius
@export var min_spawn_distance_from_player: float = 1200.0  # Min distance from player

@export_group("Neutron Fields")
@export var neutron_field_first_level: int = 0  # Level 1 density
@export var neutron_field_last_level: int = 4  # Level 14 density

@export_group("Force Fields")
@export var force_field_first_level: int = 0  # Level 1 density
@export var force_field_last_level: int = 4  # Level 14 density
@export var hazard_scenes: Array[PackedScene] = []

@export_group("Photons")
@export var photon_first_level: int = 30  # Level 1 density
@export var photon_last_level: int = 90  # Level 14 density
@export var photon_spawn_distance_min: float = 200.0
@export var photon_spawn_distance_max: float = 2000.0

@export_group("Neutrinos")
@export var neutrino_first_level: int = 0  # Level 1 density
@export var neutrino_last_level: int = 28  # Level 14 density
@export var neutrino_speed_min: float = 300.0
@export var neutrino_speed_max: float = 450.0

# Scene references
const PhotonScene = preload("res://Scenes/photon.tscn")
const NeutrinoScene = preload("res://Scenes/neutrino.tscn")
const NeutronFieldScene = preload("res://Scenes/NeutronField.tscn")

# Entity tracking
var neutron_fields: Array[Area2D] = []
var force_fields: Array[Area2D] = []
var collectibles: Array[Area2D] = []
var neutrinos: Array[Area2D] = []

# State
var goal_position: Vector2 = Vector2(2720.0, 1900.0)
var _spawn_check_timer: float = 0.0
var current_phase: int = 1  # Current phase index (1-14)

# References (set by game)
var player: Node2D = null
var camera: Camera2D = null
var hazards_root: Node2D = null
var collectibles_root: Node2D = null
var game_node: Node = null

func _process(delta: float) -> void:
	_spawn_check_timer -= delta
	
	if _spawn_check_timer <= 0.0:
		_spawn_check_timer = spawn_check_interval  # Reset to interval, not accumulate negative time
		_check_and_spawn_entities()
		_despawn_distant_entities()

func setup_references(p_player: Node2D, p_camera: Camera2D, p_hazards_root: Node2D, p_collectibles_root: Node2D, p_game: Node) -> void:
	"""Called by game to set up required node references"""
	player = p_player
	camera = p_camera
	hazards_root = p_hazards_root
	collectibles_root = p_collectibles_root
	game_node = p_game

func set_current_phase(phase: int) -> void:
	"""Update current phase index (1-14) for density scaling"""
	current_phase = clamp(phase, 1, 14)

func _get_trajectory_line_multiplier() -> float:
	"""Calculate trajectory line visibility multiplier (1.0 for easy, 0.33 for hard)"""
	if current_phase <= 1:
		return 1.0
	if current_phase >= 14:
		return 0.33
	
	# Linear interpolation from 1.0 (level 1) to 0.33 (level 14)
	var t = float(current_phase - 1) / 13.0
	return lerp(1.0, 0.33, t)

func _get_scaled_density(first_level: int, last_level: int) -> int:
	"""Calculate density for current phase using linear interpolation"""
	if current_phase <= 1:
		return first_level
	if current_phase >= 14:
		return last_level
	
	# Linear interpolation between level 1 and level 14
	var t = float(current_phase - 1) / 13.0  # Normalize to 0.0-1.0
	return int(lerp(float(first_level), float(last_level), t))

func spawn_initial_entities() -> void:
	"""Spawn initial set of entities at game start"""
	# Don't spawn hazards if we've reached stable Pb-206
	if _is_stable_isotope():
		print("Stable isotope reached - not spawning hazards")
		return
	
	randomize_goal_position()
	
	# Calculate densities based on current phase
	var neutron_density = _get_scaled_density(neutron_field_first_level, neutron_field_last_level)
	var force_density = _get_scaled_density(force_field_first_level, force_field_last_level)
	var photon_density = _get_scaled_density(photon_first_level, photon_last_level)
	var neutrino_density = _get_scaled_density(neutrino_first_level, neutrino_last_level)
	
	# Spawn entities (level 1 will have 0 hazards naturally from scaling)
	_spawn_neutron_fields(neutron_density)
	_spawn_force_fields(force_density)
	_spawn_photons(photon_density)
	_spawn_neutrinos(neutrino_density)
	
	# Make goal area dangerous with extra neutrinos and hazards
	_spawn_goal_area_dangers(neutrino_density)

func clear_all_entities() -> void:
	"""Clear all spawned entities"""
	clear_neutron_fields()
	clear_force_fields()
	clear_collectibles()
	clear_neutrinos()

func _check_and_spawn_entities() -> void:
	"""Check entity counts and spawn more if below target density"""
	if player == null:
		return
	
	# Don't spawn if we've reached stable Pb-206
	if _is_stable_isotope():
		return
	
	var player_pos = player.global_position
	
	# Count entities within spawn radius
	var nearby_neutron_fields = _count_nearby(neutron_fields, player_pos, spawn_radius)
	var nearby_force_fields = _count_nearby(force_fields, player_pos, spawn_radius)
	var nearby_photons = _count_nearby(collectibles, player_pos, spawn_radius)
	var nearby_neutrinos = _count_nearby(neutrinos, player_pos, spawn_radius)
	
	# Calculate current densities
	var neutron_density = _get_scaled_density(neutron_field_first_level, neutron_field_last_level)
	var force_density = _get_scaled_density(force_field_first_level, force_field_last_level)
	var photon_density = _get_scaled_density(photon_first_level, photon_last_level)
	var neutrino_density = _get_scaled_density(neutrino_first_level, neutrino_last_level)
	
	# Spawn to reach target density
	if nearby_neutron_fields < neutron_density:
		_spawn_neutron_fields(neutron_density - nearby_neutron_fields)
	
	if nearby_force_fields < force_density:
		_spawn_force_fields(force_density - nearby_force_fields)
	
	if nearby_photons < photon_density:
		_spawn_photons(photon_density - nearby_photons)
	
	if nearby_neutrinos < neutrino_density:
		_spawn_neutrinos(neutrino_density - nearby_neutrinos)
	
	# Maintain goal area danger (check every few spawn cycles to avoid over-spawning)
	if neutrino_density > 0:
		var goal_neutrinos = _count_nearby(neutrinos, goal_position, goal_radius * 1.5)
		var target_goal_neutrinos = int(neutrino_density * goal_area_neutrino_multiplier * 0.5)  # Maintain at least half
		if goal_neutrinos < target_goal_neutrinos:
			_spawn_goal_area_dangers(neutrino_density)

func _despawn_distant_entities() -> void:
	"""Remove entities that are too far from the player"""
	if player == null:
		return
	
	var player_pos = player.global_position
	
	_despawn_distant(neutron_fields, player_pos, despawn_radius)
	_despawn_distant(force_fields, player_pos, despawn_radius)
	_despawn_distant(collectibles, player_pos, despawn_radius)
	_despawn_distant(neutrinos, player_pos, despawn_radius)

func _is_stable_isotope() -> bool:
	"""Check if current isotope is stable (Pb-206)"""
	if player == null or not "isotope_key" in player:
		return false
	
	var isotope_data = IsotopeData.get_isotope(player.isotope_key)
	if isotope_data.is_empty():
		return false
	
	return isotope_data.get("decay_type") == "stable"

func _count_nearby(entities: Array, center: Vector2, radius: float) -> int:
	"""Count how many entities are within radius of center"""
	var count = 0
	for entity in entities:
		if is_instance_valid(entity) and entity.global_position.distance_to(center) <= radius:
			count += 1
	return count

func _despawn_distant(entities: Array, center: Vector2, radius: float) -> void:
	"""Remove entities beyond radius from center"""
	for i in range(entities.size() - 1, -1, -1):
		var entity = entities[i]
		if not is_instance_valid(entity):
			entities.remove_at(i)
			continue
		
		if entity.global_position.distance_to(center) > radius:
			entity.queue_free()
			entities.remove_at(i)

func randomize_goal_position() -> void:
	"""Move goal to a new random position away from player"""
	var center = player.global_position if player != null else Vector2.ZERO
	var min_center_distance = goal_radius + max(min_goal_edge_distance, 0.0) # Ensure goal is not too close to player
	var max_center_distance = max(max_goal_center_distance, min_center_distance + 300.0)

	var best_position = center + Vector2.RIGHT * max_center_distance
	for _attempt in range(48):
		var direction = Vector2.from_angle(randf() * TAU)
		var distance = randf_range(min_center_distance, max_center_distance) + 3000.0
		var candidate = center + direction * distance
		if candidate.distance_to(center) > min_center_distance:
			goal_position = candidate
			return
		best_position = candidate

	goal_position = best_position

# ========== Spawning Functions ==========

func _spawn_neutron_fields(count: int) -> void:
	if hazards_root == null or player == null or count <= 0:
		return

	for _i in range(count):
		var field = NeutronFieldScene.instantiate()
		field.position = _pick_spawn_position()
		hazards_root.add_child(field)
		neutron_fields.append(field)

func _spawn_force_fields(count: int) -> void:
	if hazards_root == null or player == null or hazard_scenes.is_empty() or count <= 0:
		return

	for _i in range(count):
		var scene = hazard_scenes.pick_random()
		var field = scene.instantiate()
		field.position = _pick_spawn_position()
		hazards_root.add_child(field)
		force_fields.append(field)

func _spawn_photons(count: int) -> void:
	if collectibles_root == null or player == null or count <= 0:
		return

	for _i in range(count):
		var photon = PhotonScene.instantiate()
		photon.position = _pick_collectible_position()
		photon.move_direction = Vector2.from_angle(randf() * TAU).normalized()
		collectibles_root.add_child(photon)
		collectibles.append(photon)
		
		# Connect collected signal to game immediately
		if game_node != null and photon.has_signal("collected"):
			if not photon.collected.is_connected(game_node._on_collectible_collected):
				photon.collected.connect(game_node._on_collectible_collected)

func _spawn_neutrinos(count: int) -> void:
	if hazards_root == null or player == null or count <= 0:
		return
	
	var trajectory_mult = _get_trajectory_line_multiplier()
	
	for _i in range(count):
		var neutrino = NeutrinoScene.instantiate()
		neutrino.position = _pick_neutrino_spawn_position()
		neutrino.speed = randf_range(neutrino_speed_min, neutrino_speed_max)
		neutrino.trajectory_multiplier = trajectory_mult  # Scale visibility based on difficulty
		
		# Set direction towards a random point that might intersect with gameplay area
		var direction_angle = randf() * TAU
		neutrino.set_direction(Vector2.from_angle(direction_angle))
		
		hazards_root.add_child(neutrino)
		neutrinos.append(neutrino)

func _spawn_goal_area_dangers(base_neutrino_density: int) -> void:
	"""Spawn extra neutrinos and hazards in/around the goal area to make it dangerous"""
	if hazards_root == null or player == null or base_neutrino_density <= 0:
		return
	
	var trajectory_mult = _get_trajectory_line_multiplier()
	var player_pos = player.global_position
	
	# Spawn 2.5x the normal neutrino density in the goal area
	var goal_neutrino_count = int(base_neutrino_density * goal_area_neutrino_multiplier)
	
	for _i in range(goal_neutrino_count):
		var neutrino = NeutrinoScene.instantiate()
		
		# Try to find a safe spawn position (not too close to player)
		var spawn_pos = Vector2.ZERO
		var valid_position = false
		for _attempt in range(10):  # Try up to 10 times to find a safe spot
			var angle = randf() * TAU
			var distance = randf_range(0.0, goal_radius * 1.3)  # Some inside, some just outside
			spawn_pos = goal_position + Vector2.from_angle(angle) * distance
			
			# Check if far enough from player
			if spawn_pos.distance_to(player_pos) >= min_spawn_distance_from_player:
				valid_position = true
				break
		
		# Skip this neutrino if we couldn't find a safe position
		if not valid_position:
			neutrino.queue_free()
			continue
		
		neutrino.position = spawn_pos
		neutrino.speed = randf_range(neutrino_speed_min, neutrino_speed_max)
		neutrino.trajectory_multiplier = trajectory_mult
		
		# 60% chance to aim toward goal center, 40% random direction
		if randf() < 0.6:
			var dir_to_goal = (goal_position - neutrino.position).normalized()
			# Add some randomness
			var angle_offset = randf_range(-0.5, 0.5)  # ~30 degrees variance
			neutrino.set_direction(dir_to_goal.rotated(angle_offset))
		else:
			neutrino.set_direction(Vector2.from_angle(randf() * TAU))
		
		hazards_root.add_child(neutrino)
		neutrinos.append(neutrino)
	
	# Spawn a few neutron fields near the goal area for additional danger
	if current_phase > 3 and goal_area_hazard_count > 0:  # Only spawn fields after early levels
		for _i in range(goal_area_hazard_count):
			var field = NeutronFieldScene.instantiate()
			
			# Try to find a safe spawn position (not too close to player)
			var field_pos = Vector2.ZERO
			var valid_position = false
			for _attempt in range(10):
				var angle = randf() * TAU
				var distance = goal_radius * randf_range(0.7, 1.1)
				field_pos = goal_position + Vector2.from_angle(angle) * distance
				
				# Check if far enough from player
				if field_pos.distance_to(player_pos) >= min_spawn_distance_from_player:
					valid_position = true
					break
			
			# Skip this field if we couldn't find a safe position
			if not valid_position:
				field.queue_free()
				continue
			
			field.position = field_pos
			hazards_root.add_child(field)
			neutron_fields.append(field)

# ========== Clear Functions ==========

func clear_neutron_fields() -> void:
	for field in neutron_fields:
		if is_instance_valid(field):
			field.queue_free()
	neutron_fields.clear()

func clear_force_fields() -> void:
	for field in force_fields:
		if is_instance_valid(field):
			field.queue_free()
	force_fields.clear()

func clear_collectibles() -> void:
	for collectible in collectibles:
		if is_instance_valid(collectible):
			collectible.queue_free()
	collectibles.clear()

func clear_neutrinos() -> void:
	for neutrino in neutrinos:
		if is_instance_valid(neutrino):
			neutrino.queue_free()
	neutrinos.clear()

# ========== Position Picking ==========

func _pick_spawn_position() -> Vector2:
	"""Pick a random spawn position around player, outside min distance"""
	if player == null:
		return Vector2.ZERO
	
	var center = player.global_position
	var angle = randf() * TAU
	var distance = randf_range(min_spawn_distance_from_player, spawn_radius)
	return center + Vector2.from_angle(angle) * distance

func _pick_collectible_position() -> Vector2:
	"""Pick a random position for collectibles"""
	var center = player.global_position if player != null else Vector2.ZERO
	var angle = randf() * TAU
	var distance = randf_range(photon_spawn_distance_min, photon_spawn_distance_max)
	return center + Vector2.from_angle(angle) * distance

func _pick_neutrino_spawn_position() -> Vector2:
	"""Pick a spawn position for neutrinos at the edge of the spawn area"""
	var center = player.global_position if player != null else Vector2.ZERO
	var angle = randf() * TAU
	var distance = spawn_radius * 1.2  # Spawn just outside main area
	return center + Vector2.from_angle(angle) * distance

func connect_photon_signals(game: Node) -> void:
	"""Connect collected signals for all photons to the game"""
	for collectible in collectibles:
		if is_instance_valid(collectible) and collectible.has_signal("collected"):
			if not collectible.collected.is_connected(game._on_collectible_collected):
				collectible.collected.connect(game._on_collectible_collected)

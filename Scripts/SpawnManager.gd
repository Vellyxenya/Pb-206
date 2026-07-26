extends Node2D

## SpawnManager - Handles dynamic spawning of collectibles, hazards, and goals
## Spawns entities around player based on density targets

# Spawn configuration
@export_group("Goal Settings")
@export var goal_radius: float = 1200.0
@export var min_goal_edge_distance: float = 900.0
@export var max_goal_center_distance: float = 5200.0

@export_group("Spawn Area")
@export var spawn_check_interval: float = 1.0  # How often to check spawn needs
@export var spawn_radius: float = 3000.0  # Spawn items within this radius of player
@export var despawn_radius: float = 4000.0  # Despawn items beyond this radius
@export var min_spawn_distance_from_player: float = 800.0  # Min distance from player

@export_group("Neutron Fields")
@export var neutron_field_target_density: int = 3  # Target count near player

@export_group("Force Fields")
@export var force_field_target_density: int = 2
@export var hazard_scenes: Array[PackedScene] = []

@export_group("Photons")
@export var photon_target_density: int = 35
@export var photon_spawn_distance_min: float = 200.0
@export var photon_spawn_distance_max: float = 2000.0

@export_group("Neutrinos")
@export var neutrino_target_density: int = 30
@export var neutrino_speed_min: float = 300.0
@export var neutrino_speed_max: float = 500.0

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

func spawn_initial_entities() -> void:
	"""Spawn initial set of entities at game start"""
	# Don't spawn hazards if we've reached stable Pb-206
	if _is_stable_isotope():
		print("Stable isotope reached - not spawning hazards")
		return
	
	randomize_goal_position()
	_spawn_neutron_fields(neutron_field_target_density)
	_spawn_force_fields(force_field_target_density)
	_spawn_photons(photon_target_density)
	_spawn_neutrinos(neutrino_target_density)

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
	
	# Spawn to reach target density
	if nearby_neutron_fields < neutron_field_target_density:
		_spawn_neutron_fields(neutron_field_target_density - nearby_neutron_fields)
	
	if nearby_force_fields < force_field_target_density:
		_spawn_force_fields(force_field_target_density - nearby_force_fields)
	
	if nearby_photons < photon_target_density:
		_spawn_photons(photon_target_density - nearby_photons)
	
	if nearby_neutrinos < neutrino_target_density:
		_spawn_neutrinos(neutrino_target_density - nearby_neutrinos)

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
	var min_center_distance = goal_radius + max(min_goal_edge_distance, 0.0)
	var max_center_distance = max(max_goal_center_distance, min_center_distance + 300.0)

	var best_position = center + Vector2.RIGHT * max_center_distance
	for _attempt in range(48):
		var direction = Vector2.from_angle(randf() * TAU)
		var distance = randf_range(min_center_distance, max_center_distance)
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
	
	for _i in range(count):
		var neutrino = NeutrinoScene.instantiate()
		neutrino.position = _pick_neutrino_spawn_position()
		neutrino.speed = randf_range(neutrino_speed_min, neutrino_speed_max)
		
		# Set direction towards a random point that might intersect with gameplay area
		var direction_angle = randf() * TAU
		neutrino.set_direction(Vector2.from_angle(direction_angle))
		
		hazards_root.add_child(neutrino)
		neutrinos.append(neutrino)

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

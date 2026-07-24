extends Node2D

@export var goal_position: Vector2 = Vector2(2720.0, 1900.0)
@export var goal_radius: float = 1200.0
@export var goal_arrow_padding: float = 42.0
@export var transition_duration: float = 0.8
@export var goal_margin: float = 220.0
@export var game_over_time_scale: float = 0.22
@export var min_goal_edge_distance: float = 900.0
@export var max_goal_center_distance: float = 5200.0
@export var neutron_field_count: int = 3
@export var neutron_field_radius: float = 240.0
@export var neutron_bleep_interval: float = 2.2
@export var neutron_kill_chance: float = 0.28
@export var hazard_min_goal_distance: float = 360.0
@export var hazard_min_player_distance: float = 820.0
@export var hazard_view_margin: float = 120.0
@export var neutron_fill_base_color: Color = Color(1.0, 0.55, 0.12, 0.16)
@export var neutron_fill_charge_color: Color = Color(1.0, 0.72, 0.22, 0.42)
@export var neutron_ring_base_color: Color = Color(1.0, 0.58, 0.18, 0.72)
@export var neutron_ring_charge_color: Color = Color(1.0, 0.78, 0.28, 1.0)

@export var hazard_scenes: Array[PackedScene] = [
	preload("res://Scenes/ProtonField.tscn"),
	preload("res://Scenes/ElectronField.tscn")
]
@export var force_field_count: int = 2
@export var photon_count: int = 45
@export var neutrino_count: int = 30
@export var neutrino_speed_min: float = 300.0
@export var neutrino_speed_max: float = 500.0
@export var points_per_second_in_goal: float = 2.0
@export var spawn_area_radius: float = 4000.0

const GOAL_VISUAL_SEGMENTS: int = 64
const PhotonScene = preload("res://Scenes/photon.tscn")
const NeutrinoScene = preload("res://Scenes/neutrino.tscn")

var is_transitioning: bool = false
var is_game_over: bool = false
var starting_isotope_key: String = ""
var current_phase_index: int = 1
var current_score: int = 0
var _bleep_time_left: float = 0.0
var _goal_bonus_accumulator: float = 0.0
var neutron_fields: Array[Area2D] = []
var force_fields: Array[Area2D] = []
var collectibles: Array[Area2D] = []
var neutrinos: Array[Area2D] = []
var active_neutron_fields: Dictionary = {}
var lucky_popup_tween: Tween
var phase_sounds: Array[AudioStream] = []
var phase_audio_player: AudioStreamPlayer

@onready var atom: RigidBody2D = $Player/Atom
@onready var camera: Camera2D = $Player/Atom/Camera2D
@onready var background: Node2D = $Background
@onready var timer_label: Label = $UI/PhaseTimerLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var goal_status_label: Label = $UI/GoalStatusLabel
@onready var transition_flash: ColorRect = $UI/TransitionFlash
@onready var game_over_overlay: ColorRect = $UI/GameOverOverlay
@onready var game_over_title: Label = $UI/GameOverOverlay/GameOverPanel/GameOverContent/GameOverTitle
@onready var restart_button: Button = $UI/GameOverOverlay/GameOverPanel/GameOverContent/ButtonRow/RestartButton
@onready var main_menu_button: Button = $UI/GameOverOverlay/GameOverPanel/GameOverContent/ButtonRow/MainMenuButton
@onready var lucky_popup_label: Label = $UI/LuckyPopupLabel
@onready var goal_area: Node2D = $GoalArea
@onready var goal_fill: Polygon2D = $GoalArea/GoalFill
@onready var goal_outline: Line2D = $GoalArea/GoalOutline
@onready var goal_arrow: Sprite2D = $Player/Atom/GoalArrow
@onready var goal_distance_label: Label = $Player/Atom/GoalDistanceLabel
@onready var hazards_root: Node2D = $Hazards
@onready var collectibles_root: Node2D = $Collectibles

func _ready() -> void:
	add_to_group("game")  # Allow hazards to find the game node
	
	if atom != null:
		starting_isotope_key = atom.isotope_key
		atom.phase_timer_finished.connect(_on_atom_phase_timer_finished)
	if restart_button != null:
		restart_button.pressed.connect(_on_restart_pressed)
	if main_menu_button != null:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if transition_flash != null:
		transition_flash.visible = false
	if game_over_overlay != null:
		game_over_overlay.visible = false
	if lucky_popup_label != null:
		lucky_popup_label.visible = false
	Engine.time_scale = 1.0
	
	current_score = 0
	_update_score_display()

	_setup_phase_audio()
	_play_sound_for_phase(current_phase_index)

	_rebuild_goal_visual()
	randomize_goal_position()
	spawn_hazards()
	spawn_collectibles()
	_update_goal_area_visual()
	_update_goal_status(false)
	_update_goal_guidance(false)

func _process(_delta):
	if background != null:
		var background_anchor = atom.global_position if atom != null else Vector2.ZERO
		if camera != null:
			background_anchor = camera.global_position
		background.set_view_center(background_anchor)

	if atom != null and timer_label != null and atom.has_method("get_phase_time_left"):
		var time_left = atom.get_phase_time_left()
		var isotope_data = IsotopeData.get_isotope(atom.isotope_key)
		var isotope_name = isotope_data.get("name", atom.isotope_key)
		var decay_type = isotope_data.get("decay_type", "unknown")
		
		# Format decay type for display
		var decay_display = ""
		if decay_type == "alpha":
			decay_display = "α-decay"
		elif decay_type == "beta":
			decay_display = "β-decay"
		elif decay_type == "stable":
			decay_display = "STABLE"
		else:
			decay_display = decay_type
		
		timer_label.text = "Phase " + str(current_phase_index) + "/14: " + isotope_name + " (" + decay_display + ")\nTime: " + str(snapped(time_left, 0.1))

	var in_finish_area := is_atom_in_finish_area()
	_update_goal_area_visual()
	_update_goal_status(in_finish_area)
	_update_goal_guidance(in_finish_area)
	
	# Award points per second while in goal area
	if in_finish_area and not is_transitioning and not is_game_over:
		_goal_bonus_accumulator += points_per_second_in_goal * _delta
		if _goal_bonus_accumulator >= 1.0:
			var points_to_add = int(_goal_bonus_accumulator)
			_goal_bonus_accumulator -= float(points_to_add)
			add_score(points_to_add)

func _physics_process(delta: float) -> void:
	if is_transitioning or is_game_over:
		return
	if atom == null or neutron_fields.is_empty():
		return

	_bleep_time_left -= delta
	_update_neutron_field_visuals()
	if _bleep_time_left > 0.0:
		return

	_bleep_time_left = max(neutron_bleep_interval, 0.2)
	run_neutron_bleep()

func is_atom_in_finish_area() -> bool:
	if atom == null:
		return false

	return atom.global_position.distance_to(goal_position) <= goal_radius

func _on_atom_phase_timer_finished() -> void:
	if atom == null:
		return

	if is_atom_in_finish_area():
		start_phase_transition(true)
	else:
		start_phase_transition(false, "Timer expired outside finish area")

func start_phase_transition(success: bool, death_cause: String = "") -> void:
	if is_transitioning:
		return
	is_transitioning = true

	if success:
		print("Phase success: atom in finish area at timer end.")
		# Play decay effect before transition
		if atom != null and atom.has_method("play_decay_effect"):
			var current_data = IsotopeData.get_isotope(atom.isotope_key)
			var decay_type = current_data.get("decay_type", "unknown")
			if decay_type != "stable":
				await atom.play_decay_effect(decay_type)
	else:
		print("Phase fail: atom outside finish area at timer end.")
		if atom != null and atom.has_method("play_destroy_animation"):
			await atom.play_destroy_animation()

	await play_transition_flash(success)

	if success:
		advance_to_next_phase()
	else:
		enter_game_over_state(death_cause)

	is_transitioning = false

func play_transition_flash(success: bool) -> void:
	if transition_flash == null:
		await get_tree().create_timer(transition_duration).timeout
		return

	var flash_color = Color(0.55, 0.95, 0.60, 0.0) if success else Color(0.95, 0.45, 0.45, 0.0)
	transition_flash.visible = true
	transition_flash.color = flash_color

	var tween = create_tween()
	tween.tween_property(transition_flash, "color:a", 0.45, transition_duration * 0.35)
	tween.tween_property(transition_flash, "color:a", 0.0, transition_duration * 0.65)
	await tween.finished
	transition_flash.visible = false

func randomize_goal_position() -> void:
	var center = atom.global_position if atom != null else Vector2.ZERO
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

func advance_to_next_phase() -> void:
	is_game_over = false
	Engine.time_scale = 1.0
	if game_over_overlay != null:
		game_over_overlay.visible = false

	var advanced = false
	if atom != null:
		atom.on_phase_completed()
		var current_data = IsotopeData.get_isotope(atom.isotope_key)
		
		# Check if we've reached stable Pb-206 (no next isotope)
		if not current_data.is_empty() and current_data.get("next_isotope") == null:
			# Victory! Reached stable isotope
			show_victory_screen()
			return
		
		if not current_data.is_empty() and current_data.get("next_isotope") != null:
			var decay_type = current_data.get("decay_type", "alpha")
			atom.isotope_key = str(current_data.next_isotope)
			
			# Set charge based on decay type
			# Beta decay emits an electron, leaving the atom with +1 charge
			# Alpha decay removes 2p+2n, atom remains neutral (0 charge)
			if decay_type == "beta":
				atom.set_charge(1)
				print("β-decay occurred: atom is now positively charged (+1)")
			else:
				atom.set_charge(0)
				print("α-decay occurred: atom remains neutral (0)")
			
			advanced = true

	if advanced:
		current_phase_index += 1
	_play_sound_for_phase(current_phase_index)

	randomize_goal_position()
	spawn_hazards()
	spawn_collectibles()
	if atom != null:
		atom.load_isotope_data()
		atom.reset_phase_visuals()

func show_victory_screen() -> void:
	is_game_over = true
	Engine.time_scale = 0.5
	if game_over_overlay != null:
		game_over_overlay.visible = true
	if game_over_title != null:
		game_over_title.text = "VICTORY!\n\nYou reached stable Lead-206!\n\nFinal Score: " + str(current_score)
	print("Victory! Reached stable Pb-206 with score: ", current_score)

func restart_current_phase() -> void:
	is_game_over = false
	is_transitioning = false
	Engine.time_scale = 1.0
	if game_over_overlay != null:
		game_over_overlay.visible = false

	current_score = 0
	_goal_bonus_accumulator = 0.0
	_update_score_display()

	if atom != null and not starting_isotope_key.is_empty():
		atom.isotope_key = starting_isotope_key
	current_phase_index = 1
	_play_sound_for_phase(current_phase_index)

	randomize_goal_position()
	spawn_hazards()
	spawn_collectibles()
	if atom != null:
		atom.set_charge(0)  # Reset to neutral on restart
		atom.load_isotope_data()
		atom.reset_phase_visuals()

func enter_game_over_state(death_cause: String = "Timer expired outside finish area") -> void:
	is_game_over = true
	Engine.time_scale = game_over_time_scale
	if game_over_overlay != null:
		game_over_overlay.visible = true
	if game_over_title != null:
		game_over_title.text = "GAME OVER\n" + death_cause

func spawn_hazards() -> void:
	spawn_neutron_fields()
	spawn_force_fields()
	spawn_neutrinos()

func spawn_collectibles() -> void:
	clear_collectibles()
	if collectibles_root == null or atom == null:
		return
	
	var photons_to_spawn = max(photon_count, 0)
	print("Spawning ", photons_to_spawn, " photons")
	for _i in range(photons_to_spawn):
		var photon = PhotonScene.instantiate()
		photon.position = _pick_collectible_position()
		photon.move_direction = Vector2.from_angle(randf() * TAU).normalized()
		photon.collected.connect(_on_collectible_collected)
		collectibles_root.add_child(photon)
		collectibles.append(photon)
	print("Photons spawned: ", collectibles.size())

func clear_collectibles() -> void:
	for collectible in collectibles:
		if is_instance_valid(collectible):
			collectible.queue_free()
	collectibles.clear()

func _pick_collectible_position() -> Vector2:
	"""Pick a random position for collectibles, spread widely across the map"""
	var center = atom.global_position if atom != null else Vector2.ZERO
	var angle = randf() * TAU
	var distance = randf_range(200.0, spawn_area_radius)
	return center + Vector2.from_angle(angle) * distance

func _on_collectible_collected(_collector: Node2D, points: int) -> void:
	add_score(points)
	print("Collected! +", points, " points. Total: ", current_score)

func add_score(points: int) -> void:
	current_score += points
	_update_score_display()

func _update_score_display() -> void:
	if score_label != null:
		score_label.text = "Score: " + str(current_score)

func spawn_force_fields() -> void:
	clear_force_fields()
	if hazards_root == null or atom == null or hazard_scenes.is_empty():
		return

	var fields_to_make = max(force_field_count, 0)
	for _i in fields_to_make:
		var scene = hazard_scenes.pick_random()
		var field = scene.instantiate()
		field.position = _pick_hazard_position()
		hazards_root.add_child(field)
		force_fields.append(field)

func spawn_neutron_fields() -> void:
	clear_neutron_fields()
	if hazards_root == null or atom == null:
		return

	var fields_to_make = max(neutron_field_count, 0)
	for _idx in range(fields_to_make):
		var field = _create_neutron_field(neutron_field_radius)
		field.position = _pick_hazard_position()
		hazards_root.add_child(field)
		neutron_fields.append(field)

	_bleep_time_left = max(neutron_bleep_interval, 0.2)

func clear_neutron_fields() -> void:
	for field in neutron_fields:
		if is_instance_valid(field):
			field.queue_free()
	neutron_fields.clear()
	active_neutron_fields.clear()

func clear_force_fields() -> void:
	for field in force_fields:
		if is_instance_valid(field):
			field.queue_free()
	force_fields.clear()

func spawn_neutrinos() -> void:
	clear_neutrinos()
	if hazards_root == null or atom == null:
		return
	
	var neutrinos_to_spawn = max(neutrino_count, 0)
	print("Spawning ", neutrinos_to_spawn, " neutrinos")
	for _i in range(neutrinos_to_spawn):
		var neutrino = NeutrinoScene.instantiate()
		neutrino.position = _pick_neutrino_spawn_position()
		neutrino.speed = randf_range(neutrino_speed_min, neutrino_speed_max)
		
		# Set direction towards a random point that might intersect with gameplay area
		var direction_angle = randf() * TAU
		neutrino.set_direction(Vector2.from_angle(direction_angle))
		
		hazards_root.add_child(neutrino)
		neutrinos.append(neutrino)
	print("Neutrinos spawned: ", neutrinos.size())

func clear_neutrinos() -> void:
	for neutrino in neutrinos:
		if is_instance_valid(neutrino):
			neutrino.queue_free()
	neutrinos.clear()

func _pick_neutrino_spawn_position() -> Vector2:
	"""Pick a spawn position for neutrinos at the edge of the play area"""
	var center = atom.global_position if atom != null else Vector2.ZERO
	var angle = randf() * TAU
	var distance = spawn_area_radius * 1.2  # Spawn outside main area
	return center + Vector2.from_angle(angle) * distance

func on_player_neutrino_death() -> void:
	"""Called when a neutrino hits the player"""
	print("Player hit by neutrino!")
	if atom != null and atom.has_method("play_destroy_animation"):
		await atom.play_destroy_animation()
	enter_game_over_state("Destroyed by neutrino collision!")

func _create_neutron_field(radius: float) -> Area2D:
	var field := Area2D.new()
	field.name = "NeutronField"
	field.monitoring = true
	field.collision_mask = 1
	field.body_entered.connect(_on_neutron_field_body_entered.bind(field))
	field.body_exited.connect(_on_neutron_field_body_exited.bind(field))

	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision.shape = circle
	field.add_child(collision)

	var ring_points := PackedVector2Array()
	var fill_points := PackedVector2Array()
	const SEGMENTS := 40
	for i in range(SEGMENTS):
		var angle = (float(i) / float(SEGMENTS)) * TAU
		var point = Vector2.from_angle(angle) * radius
		ring_points.append(point)
		fill_points.append(point)
	ring_points.append(ring_points[0])

	var fill := Polygon2D.new()
	fill.polygon = fill_points
	fill.color = neutron_fill_base_color
	field.add_child(fill)

	var ring := Line2D.new()
	ring.points = ring_points
	ring.width = 7.0
	ring.default_color = neutron_ring_base_color
	ring.antialiased = true
	field.add_child(ring)

	field.set_meta("hazard_fill", fill)
	field.set_meta("hazard_ring", ring)

	return field

func _on_neutron_field_body_entered(body: Node, field: Area2D) -> void:
	if atom == null or field == null:
		return
	if body == atom:
		active_neutron_fields[field.get_instance_id()] = field

func _on_neutron_field_body_exited(body: Node, field: Area2D) -> void:
	if atom == null or field == null:
		return
	if body == atom:
		active_neutron_fields.erase(field.get_instance_id())

func _pick_hazard_position() -> Vector2:
	var center = atom.global_position if atom != null else Vector2.ZERO
	var view_center = camera.global_position if camera != null else center
	var viewport_size = get_viewport_rect().size
	var half_view = viewport_size * 0.5
	var margin = max(hazard_view_margin, neutron_field_radius + 24.0)

	var min_x = view_center.x - half_view.x + margin
	var max_x = view_center.x + half_view.x - margin
	var min_y = view_center.y - half_view.y + margin
	var max_y = view_center.y + half_view.y - margin

	var min_player_dist = max(hazard_min_player_distance + neutron_field_radius, 120.0)
	var min_goal_dist = goal_radius + neutron_field_radius + max(hazard_min_goal_distance, 0.0)
	var max_player_dist = max(min(half_view.x, half_view.y) - margin, min_player_dist + 40.0)
	max_player_dist = max(max_player_dist, min_player_dist + 40.0)

	for _attempt in range(180):
		var angle = randf() * TAU
		var dist = randf_range(min_player_dist, max_player_dist)
		var candidate = center + Vector2.from_angle(angle) * dist
		candidate.x = clamp(candidate.x, min_x, max_x)
		candidate.y = clamp(candidate.y, min_y, max_y)

		if candidate.distance_to(center) < min_player_dist:
			continue
		if candidate.distance_to(goal_position) < min_goal_dist:
			continue
		return candidate

	# Fallback still guarantees distance from player, even if goal-separation can't be satisfied.
	var away_from_player = (view_center - center).normalized()
	if away_from_player.length_squared() < 0.01:
		away_from_player = Vector2.RIGHT
	var fallback = center + away_from_player * min_player_dist
	fallback.x = clamp(fallback.x, min_x, max_x)
	fallback.y = clamp(fallback.y, min_y, max_y)

	# Keep minimum distance from player after viewport clamping.
	var to_fallback = fallback - center
	if to_fallback.length() < min_player_dist:
		to_fallback = to_fallback.normalized() if to_fallback.length_squared() > 0.001 else Vector2.RIGHT
		fallback = center + to_fallback * min_player_dist
		fallback.x = clamp(fallback.x, min_x, max_x)
		fallback.y = clamp(fallback.y, min_y, max_y)

	return fallback

func run_neutron_bleep() -> void:
	if atom == null or neutron_fields.is_empty():
		return

	var survived_inside_field = false
	for field in neutron_fields:
		if not is_instance_valid(field):
			continue

		var active_by_trigger = active_neutron_fields.has(field.get_instance_id())
		var active_by_distance = is_atom_inside_field(field)
		if not active_by_trigger and not active_by_distance:
			continue

		if randf() <= clamp(neutron_kill_chance, 0.0, 1.0):
			start_phase_transition(false, "Neutron field spike")
			return
		survived_inside_field = true

	if survived_inside_field:
		show_lucky_popup(atom.global_position + Vector2(0.0, -80.0))

func _update_neutron_field_visuals() -> void:
	if neutron_fields.is_empty():
		return

	var interval = max(neutron_bleep_interval, 0.2)
	var time_left = clamp(_bleep_time_left, 0.0, interval)
	var charge = 1.0 - (time_left / interval)

	for field in neutron_fields:
		if not is_instance_valid(field):
			continue

		var fill = field.get_meta("hazard_fill", null) as Polygon2D
		if fill != null:
			fill.color = neutron_fill_base_color.lerp(neutron_fill_charge_color, charge)

		var ring = field.get_meta("hazard_ring", null) as Line2D
		if ring != null:
			ring.default_color = neutron_ring_base_color.lerp(neutron_ring_charge_color, charge)

func is_atom_inside_field(field: Area2D) -> bool:
	if atom == null or field == null:
		return false

	var collision = field.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return false

	var circle = collision.shape as CircleShape2D
	if circle == null:
		return false

	# Include atom body radius so touching the field counts as being inside it.
	var atom_radius = _get_atom_collision_radius()
	return atom.global_position.distance_to(field.global_position) <= circle.radius + atom_radius

func _get_atom_collision_radius() -> float:
	if atom == null:
		return 0.0

	var atom_collision = atom.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if atom_collision == null:
		return 0.0

	var atom_circle = atom_collision.shape as CircleShape2D
	if atom_circle == null:
		return 0.0

	return atom_circle.radius

func show_lucky_popup(world_pos: Vector2) -> void:
	if lucky_popup_label == null:
		return

	if lucky_popup_tween != null:
		lucky_popup_tween.kill()

	var viewport_pos = get_viewport().get_canvas_transform() * world_pos
	lucky_popup_label.text = "I got lucky"
	lucky_popup_label.visible = true
	lucky_popup_label.position = viewport_pos
	lucky_popup_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

	lucky_popup_tween = create_tween()
	lucky_popup_tween.tween_property(lucky_popup_label, "position", viewport_pos + Vector2(0.0, -48.0), 0.95)
	lucky_popup_tween.parallel().tween_property(lucky_popup_label, "modulate:a", 0.0, 0.95)
	await lucky_popup_tween.finished
	lucky_popup_label.visible = false

func _on_restart_pressed() -> void:
	restart_current_phase()

func _on_main_menu_pressed() -> void:
	Engine.time_scale = 1.0
	if ResourceLoader.exists("res://Scenes/main_menu.tscn"):
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	else:
		print("Main menu scene missing; closing game.")
		get_tree().quit()

func _update_goal_area_visual() -> void:
	if goal_area != null:
		goal_area.global_position = goal_position

func _rebuild_goal_visual() -> void:
	if goal_fill == null or goal_outline == null:
		return

	var fill_points := PackedVector2Array()
	var outline_points := PackedVector2Array()
	for index in range(GOAL_VISUAL_SEGMENTS):
		var angle = (float(index) / float(GOAL_VISUAL_SEGMENTS)) * TAU - PI * 0.5
		var point = Vector2.from_angle(angle) * goal_radius
		fill_points.append(point)
		outline_points.append(point)

	if not outline_points.is_empty():
		outline_points.append(outline_points[0])

	goal_fill.polygon = fill_points
	goal_outline.points = outline_points
	goal_outline.width = clamp(goal_radius * 0.05, 4.0, 18.0)

func _update_goal_status(in_finish_area: bool) -> void:
	if goal_status_label == null:
		return

	goal_status_label.text = "Finish Area: IN" if in_finish_area else "Finish Area: OUT.\nHurry to the area before the timer runs out!"
	goal_status_label.modulate = Color(0.18, 0.62, 0.22) if in_finish_area else Color(0.82, 0.2, 0.2)

func _update_goal_guidance(in_finish_area: bool) -> void:
	if atom == null or goal_arrow == null or goal_distance_label == null:
		return

	var timer_active = atom.has_method("is_phase_active") and atom.is_phase_active()
	var to_goal = goal_position - atom.global_position
	var distance = to_goal.length()
	var edge_distance = max(distance - goal_radius, 0.0)
	var show_guidance = timer_active and not is_transitioning and not is_game_over and not in_finish_area and distance > 1.0

	goal_arrow.visible = show_guidance
	goal_distance_label.visible = show_guidance
	if not show_guidance:
		return

	var direction = to_goal / distance
	var arrow_offset = direction * _get_goal_arrow_distance()
	goal_arrow.position = arrow_offset
	goal_arrow.rotation = direction.angle() + PI / 2.0
	goal_distance_label.position = arrow_offset + direction * 42.0 + Vector2(-22.0, -10.0)
	goal_distance_label.text = str(int(round(edge_distance / 10.0)))

func _get_goal_arrow_distance() -> float:
	if atom == null:
		return goal_arrow_padding

	var collision_shape = atom.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return goal_arrow_padding

	var circle = collision_shape.shape as CircleShape2D
	if circle == null:
		return goal_arrow_padding

	return circle.radius + goal_arrow_padding

func _setup_phase_audio() -> void:
	phase_audio_player = AudioStreamPlayer.new()
	phase_audio_player.name = "PhaseAudioPlayer"
	phase_audio_player.bus = "Master"
	phase_audio_player.autoplay = false
	add_child(phase_audio_player)

	phase_sounds = _load_phase_sounds()

func _load_phase_sounds() -> Array[AudioStream]:
	var sounds: Array[AudioStream] = []
	var entries: Array[Dictionary] = []

	var dir = DirAccess.open("res://Assets/Sounds")
	if dir == null:
		push_warning("Assets/Sounds folder not found. Phase sounds disabled.")
		return sounds

	for file_name in dir.get_files():
		if file_name.ends_with(".import"):
			continue
		var phase_number = _extract_phase_number(file_name)
		if phase_number <= 0:
			continue
		entries.append({
			"phase": phase_number,
			"path": "res://Assets/Sounds/" + file_name
		})

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["phase"]) < int(b["phase"]) )

	for entry in entries:
		var stream = load(String(entry["path"])) as AudioStream
		if stream != null:
			sounds.append(stream)

	return sounds

func _extract_phase_number(file_name: String) -> int:
	var base = file_name.get_basename().to_lower()
	if not base.begins_with("kf"):
		return -1

	var digits = ""
	for i in range(2, base.length()):
		var ch = base.substr(i, 1)
		if ch >= "0" and ch <= "9":
			digits += ch
		else:
			break

	if digits.is_empty():
		return -1
	return int(digits)

func _play_sound_for_phase(phase_index: int) -> void:
	if phase_audio_player == null or phase_sounds.is_empty():
		return
	if phase_index <= 0:
		return
	if phase_index > phase_sounds.size():
		push_warning("No phase sound found for phase " + str(phase_index))
		return

	phase_audio_player.stop()
	phase_audio_player.stream = phase_sounds[phase_index - 1]
	phase_audio_player.play()

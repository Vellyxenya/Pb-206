extends Node2D

@export var goal_position: Vector2 = Vector2(2720.0, 1900.0)
@export var goal_radius: float = 1200.0
@export var goal_arrow_padding: float = 42.0
@export var transition_duration: float = 0.8
@export var goal_margin: float = 220.0
@export var game_over_time_scale: float = 0.22
@export var min_goal_edge_distance: float = 900.0
@export var max_goal_center_distance: float = 5200.0

const GOAL_VISUAL_SEGMENTS: int = 64

var is_transitioning: bool = false
var is_game_over: bool = false
var starting_isotope_key: String = ""

@onready var atom: RigidBody2D = $Player/Atom
@onready var camera: Camera2D = $Player/Atom/Camera2D
@onready var background: Node2D = $Background
@onready var timer_label: Label = $UI/PhaseTimerLabel
@onready var goal_status_label: Label = $UI/GoalStatusLabel
@onready var transition_flash: ColorRect = $UI/TransitionFlash
@onready var game_over_overlay: ColorRect = $UI/GameOverOverlay
@onready var game_over_title: Label = $UI/GameOverOverlay/GameOverPanel/GameOverContent/GameOverTitle
@onready var restart_button: Button = $UI/GameOverOverlay/GameOverPanel/GameOverContent/ButtonRow/RestartButton
@onready var main_menu_button: Button = $UI/GameOverOverlay/GameOverPanel/GameOverContent/ButtonRow/MainMenuButton
@onready var goal_area: Node2D = $GoalArea
@onready var goal_fill: Polygon2D = $GoalArea/GoalFill
@onready var goal_outline: Line2D = $GoalArea/GoalOutline
@onready var goal_arrow: Sprite2D = $Player/Atom/GoalArrow
@onready var goal_distance_label: Label = $Player/Atom/GoalDistanceLabel

func _ready() -> void:
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
	Engine.time_scale = 1.0

	_rebuild_goal_visual()
	randomize_goal_position()
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
		timer_label.text = "Time: " + str(snapped(atom.get_phase_time_left(), 0.1))

	var in_finish_area := is_atom_in_finish_area()
	_update_goal_area_visual()
	_update_goal_status(in_finish_area)
	_update_goal_guidance(in_finish_area)

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
		start_phase_transition(false)

func start_phase_transition(success: bool) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	if success:
		print("Phase success: atom in finish area at timer end.")
	else:
		print("Phase fail: atom outside finish area at timer end.")
		if atom != null and atom.has_method("play_destroy_animation"):
			await atom.play_destroy_animation()

	await play_transition_flash(success)

	if success:
		advance_to_next_phase()
	else:
		enter_game_over_state()

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

	if atom != null:
		atom.on_phase_completed()
		var current_data = IsotopeData.get_isotope(atom.isotope_key)
		if not current_data.is_empty() and current_data.get("next_isotope") != null:
			atom.isotope_key = str(current_data.next_isotope)

	randomize_goal_position()
	if atom != null:
		atom.load_isotope_data()
		atom.reset_phase_visuals()

func restart_current_phase() -> void:
	is_game_over = false
	is_transitioning = false
	Engine.time_scale = 1.0
	if game_over_overlay != null:
		game_over_overlay.visible = false

	if atom != null and not starting_isotope_key.is_empty():
		atom.isotope_key = starting_isotope_key

	randomize_goal_position()
	if atom != null:
		atom.load_isotope_data()
		atom.reset_phase_visuals()

func enter_game_over_state() -> void:
	is_game_over = true
	Engine.time_scale = game_over_time_scale
	if game_over_overlay != null:
		game_over_overlay.visible = true
	if game_over_title != null:
		game_over_title.text = "GAME OVER\nTimer expired outside finish area"

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

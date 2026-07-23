extends Node2D

@export var goal_position: Vector2 = Vector2(2720.0, 1900.0)
@export var goal_radius: float = 1200.0
@export var goal_arrow_padding: float = 42.0

const GOAL_VISUAL_SEGMENTS: int = 64

@onready var atom: RigidBody2D = $Player/Atom
@onready var camera: Camera2D = $Player/Atom/Camera2D
@onready var background: Node2D = $Background
@onready var timer_label: Label = $UI/PhaseTimerLabel
@onready var goal_status_label: Label = $UI/GoalStatusLabel
@onready var goal_area: Node2D = $GoalArea
@onready var goal_fill: Polygon2D = $GoalArea/GoalFill
@onready var goal_outline: Line2D = $GoalArea/GoalOutline
@onready var goal_arrow: Sprite2D = $Player/Atom/GoalArrow
@onready var goal_distance_label: Label = $Player/Atom/GoalDistanceLabel

func _ready() -> void:
	if atom != null:
		atom.phase_timer_finished.connect(_on_atom_phase_timer_finished)

	_rebuild_goal_visual()
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
		print("Timer ended while inside finish area.")
		atom.on_phase_completed()
	else:
		print("Timer ended outside finish area.")

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
	var show_guidance = timer_active and not in_finish_area and distance > 1.0

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

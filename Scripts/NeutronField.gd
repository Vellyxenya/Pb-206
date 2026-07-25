extends Area2D

## NeutronField - A hazardous area that periodically checks for player kills

@export var radius: float = 240.0
@export var bleep_interval: float = 2.2
@export var kill_chance: float = 0.28
@export var fill_base_color: Color = Color(1.0, 0.55, 0.12, 0.16)
@export var fill_charge_color: Color = Color(1.0, 0.72, 0.22, 0.42)
@export var ring_base_color: Color = Color(1.0, 0.58, 0.18, 0.72)
@export var ring_charge_color: Color = Color(1.0, 0.78, 0.28, 1.0)

var _bleep_timer: float = 0.0
var _player_inside: bool = false
var _player: Node2D = null

@onready var fill: Polygon2D = $Fill
@onready var ring: Line2D = $Ring

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_bleep_timer = bleep_interval
	_setup_visuals()

func _setup_visuals() -> void:
	"""Create the visual polygons for the neutron field"""
	if fill == null or ring == null:
		return
	
	var ring_points := PackedVector2Array()
	var fill_points := PackedVector2Array()
	const SEGMENTS := 40
	for i in range(SEGMENTS):
		var angle = (float(i) / float(SEGMENTS)) * TAU
		var point = Vector2.from_angle(angle) * radius
		ring_points.append(point)
		fill_points.append(point)
	ring_points.append(ring_points[0])
	
	fill.polygon = fill_points
	fill.color = fill_base_color
	
	ring.points = ring_points
	ring.width = 7.0
	ring.default_color = ring_base_color
	ring.antialiased = true

func _process(delta: float) -> void:
	_bleep_timer -= delta
	
	if _bleep_timer <= 0.0:
		_bleep_timer = bleep_interval
		_run_bleep()
	
	_update_visuals()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_atom") or body.name == "Atom":
		_player_inside = true
		_player = body

func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player_inside = false
		_player = null

func _run_bleep() -> void:
	"""Periodic check - chance to kill player if inside"""
	if not _player_inside or _player == null:
		return
	
	if randf() < kill_chance:
		# Player dies - notify game
		var game = get_tree().get_first_node_in_group("game")
		if game and game.has_method("on_player_neutron_death_from_field"):
			game.on_player_neutron_death_from_field()
	else:
		# Player survived - show popup
		var game = get_tree().get_first_node_in_group("game")
		if game and game.has_method("show_lucky_popup"):
			game.show_lucky_popup()

func _update_visuals() -> void:
	"""Update field colors based on player charge state"""
	if fill == null or ring == null:
		return
	
	var use_charged_color = false
	
	if _player_inside and _player != null and _player.has_method("get_charge"):
		var charge = _player.get_charge()
		use_charged_color = (charge > 0)
	
	if use_charged_color:
		fill.color = fill_charge_color
		ring.default_color = ring_charge_color
	else:
		fill.color = fill_base_color
		ring.default_color = ring_base_color

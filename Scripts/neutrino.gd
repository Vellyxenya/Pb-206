extends Area2D

## Neutrino - a fast-moving hazard with visible trajectory

@export var speed: float = 400.0
@export var trajectory_line_duration: float = 5.0
@export var visual_radius: float = 14.0

var direction: Vector2 = Vector2.RIGHT
var _has_killed: bool = false

@onready var trajectory_line: Line2D = $TrajectoryLine
@onready var visual: Node2D = $Visual

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("neutrinos")
	_update_trajectory_line()

func _physics_process(delta: float) -> void:
	# Move in direction
	global_position += direction * speed * delta
	_update_trajectory_line()

func _update_trajectory_line() -> void:
	if trajectory_line == null:
		return
	
	# Calculate where the neutrino will be in 5 seconds
	var trajectory_end = direction * speed * trajectory_line_duration
	
	# Set line points from current position to future position
	trajectory_line.points = PackedVector2Array([
		Vector2.ZERO,
		trajectory_end
	])

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	_update_trajectory_line()

func _on_body_entered(body: Node2D) -> void:
	if _has_killed:
		return
	
	# Check if it's the player atom
	if body.is_in_group("player_atom") or body.name == "Atom":
		_has_killed = true
		print("Neutrino collision! Player destroyed.")
		# Notify game of player death
		if body.has_method("on_neutrino_hit"):
			body.on_neutrino_hit()
		else:
			# Fallback: try to find game node
			var game = get_tree().get_first_node_in_group("game")
			if game and game.has_method("on_player_neutrino_death"):
				game.on_player_neutrino_death()

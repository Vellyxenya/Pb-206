extends Area2D
class_name Collectible

## Base class for all collectible items (photons, electrons, etc.)

signal collected(collector: Node2D, points: int)

@export var point_value: int = 5
@export var move_speed: float = 100.0
@export var move_direction: Vector2 = Vector2.RIGHT
@export var oscillation_amplitude: float = 30.0
@export var oscillation_frequency: float = 2.0
@export var auto_collect_radius: float = 80.0

var _time_alive: float = 0.0
var _initial_position: Vector2 = Vector2.ZERO
var _collected: bool = false

func _ready() -> void:
	_initial_position = global_position
	body_entered.connect(_on_body_entered)
	add_to_group("collectibles")

func _physics_process(delta: float) -> void:
	if _collected:
		return
	
	_time_alive += delta
	
	# Move in direction with oscillation (wave-like movement)
	var perpendicular = Vector2(-move_direction.y, move_direction.x)
	var oscillation = perpendicular * sin(_time_alive * oscillation_frequency * TAU) * oscillation_amplitude
	
	global_position += move_direction * move_speed * delta
	global_position += oscillation * delta

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	
	# Check if it's the player atom
	if body.is_in_group("player_atom") or body.name == "Atom":
		print("Photon collected by: ", body.name)
		collect(body)

func collect(collector: Node2D) -> void:
	if _collected:
		return
	
	_collected = true
	collected.emit(collector, point_value)
	
	# Play collection animation/effect
	play_collection_effect()
	
	# Remove after effect
	await get_tree().create_timer(0.2).timeout
	queue_free()

func play_collection_effect() -> void:
	# Simple fade out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)

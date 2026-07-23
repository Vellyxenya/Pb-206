extends Node2D

@onready var atom: RigidBody2D = $Atom

func _input(event: InputEvent) -> void:
	if atom == null:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_Y and atom.has_method("teleport_towards"):
		atom.teleport_towards(get_global_mouse_position(), 100.0)

func _physics_process(_delta):
	if atom != null and atom.has_method("drive_towards"):
		atom.drive_towards(get_global_mouse_position())

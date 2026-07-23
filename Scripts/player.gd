extends Node2D

@onready var atom: RigidBody2D = $Atom

func _physics_process(_delta):
	if atom != null and atom.has_method("drive_towards"):
		atom.drive_towards(get_global_mouse_position())

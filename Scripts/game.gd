extends Node2D

@onready var atom: RigidBody2D = $Player/Atom
@onready var background_material: ShaderMaterial = $BackgroundLayer/Background.material as ShaderMaterial

func _process(_delta):
	if atom != null and background_material != null:
		background_material.set_shader_parameter("world_offset", atom.global_position)

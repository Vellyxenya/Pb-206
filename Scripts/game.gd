extends Node2D

@onready var atom: RigidBody2D = $Player/Atom
@onready var background_material: ShaderMaterial = $BackgroundLayer/Background.material as ShaderMaterial
@onready var timer_label: Label = $UI/PhaseTimerLabel

func _process(_delta):
	if atom != null and background_material != null:
		background_material.set_shader_parameter("world_offset", atom.global_position)

	if atom != null and timer_label != null and atom.has_method("get_phase_time_left"):
		timer_label.text = "Time: " + str(snapped(atom.get_phase_time_left(), 0.1))

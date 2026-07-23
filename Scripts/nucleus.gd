extends Node2D

enum NucleusType { PROTON, NEUTRON }

const NUCLEUS_TINT_SHADER = preload("res://Assets/Shaders/NucleusTint.gdshader")

@export var nucleus_type: NucleusType = NucleusType.PROTON

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Oscillation properties
var oscillation_offset: Vector2 = Vector2.ZERO
var oscillation_speed: Vector2
var oscillation_amplitude := 3.0  # pixels
var time_offset: float
var proton_tint: Color = Color(0.95, 0.25, 0.25)
var is_destroying: bool = false

func _ready():
	add_to_group("nucleus_visual")

	# Ensure sprite is centered (pivot at center, not top-left)
	sprite.centered = true

	# Give each nucleus its own shader material so per-instance tint can vary.
	var tint_material := ShaderMaterial.new()
	tint_material.shader = NUCLEUS_TINT_SHADER
	sprite.material = tint_material
	_apply_tint_state()
	
	# Random oscillation parameters for each nucleus
	oscillation_speed = Vector2(
		randf_range(0.5, 1.5),  # X speed
		randf_range(0.5, 1.5)   # Y speed
	)
	time_offset = randf() * TAU  # Random start phase
	
	# Play spawn animation first
	sprite.play("spawn")
	sprite.animation_finished.connect(_on_spawn_finished)

func _process(delta):
	# Gentle sinusoidal oscillation applied to SPRITE position, not node position
	var time = Time.get_ticks_msec() / 1000.0 + time_offset
	oscillation_offset = Vector2(
		sin(time * oscillation_speed.x) * oscillation_amplitude,
		cos(time * oscillation_speed.y) * oscillation_amplitude
	)
	
	# Apply oscillation to sprite position (offset from node's position)
	sprite.position = oscillation_offset

func _on_spawn_finished():
	if is_destroying:
		return

	if nucleus_type == NucleusType.PROTON:
		sprite.play("proton")
	else:
		sprite.play("neutron")

func play_destroy_animation() -> void:
	if sprite == null:
		return

	is_destroying = true
	oscillation_amplitude = 0.0
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("destroy"):
		sprite.play("destroy")
	else:
		sprite.visible = false

func get_destroy_duration() -> float:
	if sprite == null or sprite.sprite_frames == null:
		return 0.35
	if not sprite.sprite_frames.has_animation("destroy"):
		return 0.35

	var frame_count = sprite.sprite_frames.get_frame_count("destroy")
	var speed = max(sprite.sprite_frames.get_animation_speed("destroy"), 1.0)
	return float(frame_count) / speed

func set_type(type: NucleusType, tint: Color = Color(0.95, 0.25, 0.25)):
	nucleus_type = type
	proton_tint = tint
	if is_inside_tree():
		_apply_tint_state()

func _apply_tint_state():
	var tint_material := sprite.material as ShaderMaterial
	if tint_material == null:
		return
	tint_material.set_shader_parameter("is_proton", nucleus_type == NucleusType.PROTON)
	tint_material.set_shader_parameter("proton_tint", proton_tint)

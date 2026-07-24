extends Collectible

## Photon collectible - a wave-like particle of light

@onready var visual: Node2D = $Visual

func _ready() -> void:
	super._ready()
	# Add some initial random rotation
	if visual:
		visual.rotation = randf() * TAU

func _process(delta: float) -> void:
	if _collected:
		return
	
	# Rotate the visual for wave-like appearance
	if visual:
		visual.rotation += delta * 3.0
		
		# Pulse the scale slightly
		var pulse = 1.0 + sin(_time_alive * 5.0) * 0.15
		visual.scale = Vector2(pulse, pulse)

func _on_animation_timer_timeout() -> void:
	# Optional: Add additional animation effects here
	pass

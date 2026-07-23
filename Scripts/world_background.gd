extends Node2D

@export var pattern_spacing: float = 84.0
@export var dot_spacing_multiplier: int = 2
@export var line_width: float = 2.0
@export var dot_radius: float = 5.0
@export var base_color: Color = Color(0.86, 0.94, 1.0, 1.0)
@export var line_color: Color = Color(0.74, 0.85, 0.97, 0.45)
@export var dot_color: Color = Color(0.70, 0.81, 0.93, 0.30)
@export var viewport_padding: float = 160.0

var view_center: Vector2 = Vector2.ZERO

func set_view_center(center: Vector2) -> void:
	if view_center.is_equal_approx(center):
		return

	view_center = center
	global_position = center
	queue_redraw()

func _draw() -> void:
	var viewport_size = get_viewport_rect().size
	var half_size = viewport_size * 0.5
	var draw_top_left = -half_size - Vector2.ONE * viewport_padding
	var draw_size = viewport_size + Vector2.ONE * viewport_padding * 2.0

	draw_rect(Rect2(draw_top_left, draw_size), base_color, true)

	var world_left = view_center.x + draw_top_left.x
	var world_right = world_left + draw_size.x
	var world_top = view_center.y + draw_top_left.y
	var world_bottom = world_top + draw_size.y

	var first_vertical = floor(world_left / pattern_spacing) * pattern_spacing
	var x = first_vertical
	while x <= world_right + pattern_spacing:
		var local_x = x - view_center.x
		draw_line(Vector2(local_x, draw_top_left.y), Vector2(local_x, draw_top_left.y + draw_size.y), line_color, line_width, true)
		x += pattern_spacing

	var first_horizontal = floor(world_top / pattern_spacing) * pattern_spacing
	var y = first_horizontal
	while y <= world_bottom + pattern_spacing:
		var local_y = y - view_center.y
		draw_line(Vector2(draw_top_left.x, local_y), Vector2(draw_top_left.x + draw_size.x, local_y), line_color, line_width, true)
		y += pattern_spacing

	var dot_spacing = pattern_spacing * float(dot_spacing_multiplier)
	var first_dot_x = floor(world_left / dot_spacing) * dot_spacing
	var first_dot_y = floor(world_top / dot_spacing) * dot_spacing
	var dot_x = first_dot_x
	while dot_x <= world_right + dot_spacing:
		var dot_y = first_dot_y
		while dot_y <= world_bottom + dot_spacing:
			var local_dot = Vector2(dot_x, dot_y) - view_center
			draw_circle(local_dot, dot_radius, dot_color)
			dot_y += dot_spacing
		dot_x += dot_spacing
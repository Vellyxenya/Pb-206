shader_type canvas_item;

uniform vec2 world_offset = vec2(0.0, 0.0);
uniform float pattern_scale = 42.0;
uniform float parallax_strength = 0.06;
uniform vec4 base_color : source_color = vec4(0.86, 0.94, 1.0, 1.0);
uniform vec4 line_color : source_color = vec4(0.74, 0.85, 0.97, 1.0);
uniform vec4 dot_color : source_color = vec4(0.70, 0.81, 0.93, 1.0);
uniform float line_thickness = 0.020;
uniform float dot_radius = 0.060;

void fragment() {
	vec2 uv = SCREEN_UV * pattern_scale + world_offset * parallax_strength;
	vec2 cell_index = floor(uv);
	vec2 cell_uv = fract(uv) - 0.5;
	vec2 grid = abs(cell_uv);
	vec2 grid_fw = fwidth(cell_uv);

	float line_x = 1.0 - smoothstep(line_thickness, line_thickness + grid_fw.x * 1.5, grid.x);
	float line_y = 1.0 - smoothstep(line_thickness, line_thickness + grid_fw.y * 1.5, grid.y);

	// Keep only every other line to drop the alternating shimmer-prone ones.
	float keep_vertical = 1.0 - mod(abs(cell_index.x), 2.0);
	float keep_horizontal = 1.0 - mod(abs(cell_index.y), 2.0);
	line_x *= keep_vertical;
	line_y *= keep_horizontal;

	float line_mask = max(line_x, line_y);

	float dot_dist = length(cell_uv);
	float dot_fw = max(fwidth(dot_dist), 0.0001);
	float dot_mask = 1.0 - smoothstep(dot_radius, dot_radius + dot_fw * 1.5, dot_dist);

	vec3 color = base_color.rgb;
	color = mix(color, line_color.rgb, line_mask * 0.45);
	color = mix(color, dot_color.rgb, dot_mask * 0.30);

	COLOR = vec4(color, 1.0);
}

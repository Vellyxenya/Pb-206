shader_type canvas_item;

uniform bool is_proton = false;
uniform vec4 proton_tint : source_color = vec4(1.0, 0.35, 0.35, 1.0);
uniform float white_threshold = 0.92;
uniform float target_gray = 0.811765; // 207 / 255
uniform float gray_tolerance = 0.18;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	bool is_transparent = tex.a <= 0.01;
	bool is_white = tex.r >= white_threshold && tex.g >= white_threshold && tex.b >= white_threshold;

	if (is_transparent || is_white || !is_proton) {
		COLOR = tex;
	} else {
		float max_c = max(max(tex.r, tex.g), tex.b);
		float min_c = min(min(tex.r, tex.g), tex.b);
		float channel_spread = max_c - min_c;
		float luminance = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
		bool is_gray_like = channel_spread <= 0.10;
		bool is_fill_gray_band = abs(luminance - target_gray) <= gray_tolerance;

		if (is_gray_like && is_fill_gray_band) {
			vec3 tinted = clamp(proton_tint.rgb * (0.20 + luminance), 0.0, 1.0);
			COLOR = vec4(tinted, tex.a * proton_tint.a);
		} else {
			COLOR = tex;
		}
	}
}

shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float light_angle : hint_range(0.0, 360.0) = 225.0;
uniform float rim_width : hint_range(0.0, 10.0) = 1.0;
uniform float rim_intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;

	// Sample alpha in 4 directions to find edge normal
	float a_left = texture(TEXTURE, UV + vec2(-pixel_size.x * rim_width, 0.0)).a;
	float a_right = texture(TEXTURE, UV + vec2(pixel_size.x * rim_width, 0.0)).a;
	float a_up = texture(TEXTURE, UV + vec2(0.0, -pixel_size.y * rim_width)).a;
	float a_down = texture(TEXTURE, UV + vec2(0.0, pixel_size.y * rim_width)).a;

	// Calculate edge normal from alpha gradient
	vec2 edge_normal = vec2(a_left - a_right, a_up - a_down);
	float edge_strength = length(edge_normal);

	if (edge_strength > 0.01) {
		edge_normal = normalize(edge_normal);

		// Compare edge normal to light direction
		float angle_rad = radians(light_angle);
		vec2 light_dir = vec2(cos(angle_rad), sin(angle_rad));
		float rim_factor = max(0.0, dot(edge_normal, light_dir));

		// Apply rim light
		vec3 final_color = mix(tex.rgb, rim_color.rgb, rim_factor * edge_strength * rim_intensity);
		COLOR = vec4(final_color, tex.a);
	} else {
		COLOR = tex;
	}
}

shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float light_angle : hint_range(0.0, 360.0) = 225.0;
uniform float rim_width : hint_range(0.0, 10.0) = 1.0;
uniform float rim_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float spotlight_radius : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;

	// Sample alpha in 4 directions to find edge
	float a_left = texture(TEXTURE, UV + vec2(-pixel_size.x * rim_width, 0.0)).a;
	float a_right = texture(TEXTURE, UV + vec2(pixel_size.x * rim_width, 0.0)).a;
	float a_up = texture(TEXTURE, UV + vec2(0.0, -pixel_size.y * rim_width)).a;
	float a_down = texture(TEXTURE, UV + vec2(0.0, pixel_size.y * rim_width)).a;

	// Calculate edge strength
	vec2 edge_normal = vec2(a_left - a_right, a_up - a_down);
	float edge_strength = length(edge_normal);

	if (edge_strength > 0.01) {
		vec2 norm = normalize(edge_normal);

		// Light direction and perpendicular band direction
		float angle_rad = radians(light_angle);
		vec2 light_dir = vec2(cos(angle_rad), sin(angle_rad));
		vec2 band_dir = vec2(-light_dir.y, light_dir.x);

		// Pixel position in normalized coords
		vec2 pos = UV - 0.5;

		// Where is this pixel along the band direction?
		float band_pos = dot(pos, band_dir);

		// Offset by how much the normal points along the band direction
		// This shifts where each differently-angled edge "sees" the band
		float normal_offset = dot(norm, band_dir) * 0.5;

		// Push band far away for edges not facing the light
		float facing = dot(norm, light_dir);
		if (facing <= 0.0) {
			normal_offset += 10.0;
		}

		float effective_pos = band_pos - normal_offset;

		// Is it within the light band? Band centered at 0
		bool in_band = abs(effective_pos) < spotlight_radius * 0.25;

		COLOR = in_band ? vec4(rim_color.rgb * rim_intensity, tex.a) : tex;
	} else {
		COLOR = tex;
	}
}

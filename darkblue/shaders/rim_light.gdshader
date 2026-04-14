shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float light_angle : hint_range(0.0, 360.0) = 225.0;
uniform float rim_width : hint_range(0.0, 10.0) = 1.0;
uniform float rim_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec2 center_offset = vec2(0.0, 0.0);
uniform float specular_radius : hint_range(0.0, 1.0) = 0.3;
uniform float facing_threshold : hint_range(-1.0, 1.0) = 0.0;

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

		float angle_rad = radians(light_angle);
		vec2 light_dir = vec2(cos(angle_rad), sin(angle_rad));

		// Must face the light
		float facing = dot(edge_normal, light_dir);
		if (facing > facing_threshold) {
			// Tangent is perpendicular to normal (along the edge)
			vec2 tangent = vec2(-edge_normal.y, edge_normal.x);

			// Pixel position normalized to actual pixels, not UV
			// This fixes sprite sheet aspect ratio issues
			vec2 pos = (UV - 0.5 + center_offset) / TEXTURE_PIXEL_SIZE;
			// Normalize to roughly -0.5 to 0.5 range based on sprite size
			float sprite_size = 1.0 / max(TEXTURE_PIXEL_SIZE.x, TEXTURE_PIXEL_SIZE.y);
			pos /= sprite_size;
			float pixel_along_tangent = dot(pos, tangent);

			// Angular difference between normal and light determines highlight position
			float normal_angle = atan(edge_normal.y, edge_normal.x);
			float angle_diff = angle_rad - normal_angle;

			// Convert angle diff to highlight position along edge
			// When light aligns with normal (diff=0), highlight at center
			// As diff increases, highlight slides along edge
			float highlight_center = sin(angle_diff) * 0.5;

			// Distance from this pixel to highlight center
			float dist = abs(pixel_along_tangent - highlight_center);

			bool in_light = dist < specular_radius;

			COLOR = in_light ? vec4(rim_color.rgb, tex.a) : tex;
		} else {
			COLOR = tex;
		}
	} else {
		COLOR = tex;
	}
}

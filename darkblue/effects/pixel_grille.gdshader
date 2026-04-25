shader_type canvas_item;
render_mode blend_premul_alpha;

// Size of each LCD cell in screen pixels
uniform float cell_size : hint_range(2.0, 16.0, 1.0) = 3.0;
// Alpha multiplier for the 1-pixel gap lines
uniform float gap_alpha : hint_range(0.0, 1.0) = 0.5;
uniform vec4 on_color : source_color = vec4(0.82, 0.82, 0.698, 1.0);
void fragment() {
	float intensity = texture(TEXTURE, UV).r;
	vec2 cell = mod(FRAGCOORD.xy, cell_size);
	if (cell.x < 1.0 || cell.y < 1.0) {
		intensity *= gap_alpha;
	}
	COLOR = vec4(on_color.rgb * intensity, intensity);
}

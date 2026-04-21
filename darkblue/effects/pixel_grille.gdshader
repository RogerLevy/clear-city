shader_type canvas_item;
render_mode blend_premul_alpha;
// Size of each LCD cell in screen pixels
uniform float cell_size : hint_range(2.0, 16.0, 1.0) = 3.0;
// Alpha multiplier for the 1-pixel gap lines
uniform float gap_alpha : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	vec2 cell = mod(FRAGCOORD.xy, cell_size);
	if (cell.x < 1.0 || cell.y < 1.0) {
		COLOR *= gap_alpha;
	}
}

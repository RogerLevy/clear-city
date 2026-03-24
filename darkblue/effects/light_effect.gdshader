shader_type canvas_item;
render_mode blend_sub;

// 4x4 Bayer matrix dithering
float bayer4(vec2 pos) {
	int x = int(mod(pos.x, 4.0));
	int y = int(mod(pos.y, 4.0));
	int index = x + y * 4;
	float table[16] = float[16](
		 0.0,  8.0,  2.0, 10.0,
		12.0,  4.0, 14.0,  6.0,
		 3.0, 11.0,  1.0,  9.0,
		15.0,  7.0, 13.0,  5.0
	);
	return table[index] / 16.0 - 0.5;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float dither = bayer4(FRAGCOORD.xy) / 255.0;
	COLOR = c + vec3(dither).xyzx * vec4(1.0, 1.0, 1.0, 0.0);
}

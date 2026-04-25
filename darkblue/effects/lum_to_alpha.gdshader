shader_type canvas_item;
//render_mode blend_premul_alpha;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(tex.rgb, lum);
}

shader_type canvas_item;
render_mode blend_disabled;

uniform vec3 key_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float key_threshold = 0.02;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.01) discard;
	//vec3 unpremul = tex.rgb / tex.a;
	//if (distance(tex.rgb, key_color) < key_threshold) discard;
	COLOR = tex;
}

shader_type canvas_item;

uniform sampler2D mask_texture : source_color;

void fragment() {
	if (texture(mask_texture, SCREEN_UV).a > 0.01) {
		discard;
	}
	COLOR = texture(TEXTURE, UV);
}

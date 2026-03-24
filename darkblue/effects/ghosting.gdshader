shader_type canvas_item;

void fragment() {
	vec4 prev = texture(TEXTURE, UV);

	// Discard transparent pixels
	if (prev.a < 0.01) {
		discard;
	}

	// Display as-is - fading was done when stored
	COLOR = prev;
}

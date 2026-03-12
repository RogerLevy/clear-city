shader_type canvas_item;
render_mode blend_mul;

void fragment() {
    vec4 src = texture(TEXTURE, UV) * COLOR;
    if (src.a < 1.0) {
        // Multiply dest alpha by 0.5 (dims what's behind)
        COLOR = vec4(1.0, 1.0, 1.0, 0.5);
    } else {
        // Opaque parts: output normally (but blend_mul affects this too)
        // Need blend_mix for opaque parts - can't mix modes in one shader
        COLOR = src;
    }
}

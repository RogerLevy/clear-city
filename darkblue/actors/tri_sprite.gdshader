shader_type canvas_item;
render_mode blend_disabled;

// Color key to replace with punch-through
const vec3 KEY_COLOR = vec3(0.298, 0.298, 0.498);  // #4c4c7f
const float KEY_THRESHOLD = 0.02;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Skip already-transparent pixels
    if (tex.a < 0.01) {
        discard;
    }

    // Replace key color with transparent (cuts through)
    if (distance(tex.rgb, KEY_COLOR) < KEY_THRESHOLD) {
        COLOR = vec4(0.0);
    } else {
        COLOR = tex;
    }
}

shader_type canvas_item;
render_mode blend_disabled;

varying float frame_data;

// Color key to replace with transparent
const vec3 KEY_COLOR = vec3(0.298, 0.298, 0.498);  // #4c4c7f
const float KEY_THRESHOLD = 0.02;

void vertex() {
    // Instance color's red channel contains frame / 72
    frame_data = COLOR.r;
}

void fragment() {
    float frame = floor(frame_data * 72.0);
    float frame_width = 1.0 / 72.0;
    vec2 uv = UV;
    uv.x = frame * frame_width + uv.x * frame_width;

    vec4 tex = texture(TEXTURE, uv);

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

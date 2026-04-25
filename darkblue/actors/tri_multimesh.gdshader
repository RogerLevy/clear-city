shader_type canvas_item;
render_mode blend_disabled;

varying float frame_data;

void vertex() {
    // Instance color's red channel contains normalized frame (0-1 for 24 frames)
    frame_data = COLOR.r;
}

void fragment() {
    float frame = floor(frame_data * 24.0);
    float frame_width = 1.0 / 24.0;
    vec2 uv = UV;
    uv.x = frame * frame_width + uv.x * frame_width;

    vec4 tex = texture(TEXTURE, uv);

    // Skip already-transparent pixels
    if (tex.a < 0.01) {
        discard;
    }

    COLOR = tex;
}

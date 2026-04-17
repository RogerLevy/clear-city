shader_type canvas_item;
render_mode blend_premul_alpha;

// Color key - discard these pixels to show what's below
uniform vec3 key_color : source_color = vec3(0.298, 0.298, 0.498);  // #4c4c7f
uniform float key_threshold = 0.02;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Discard transparent and key color pixels
    if (tex.a < 0.01 || distance(tex.rgb, key_color) < key_threshold) {
        discard;
    }

    //COLOR = tex * COLOR;
}

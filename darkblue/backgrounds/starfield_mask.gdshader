shader_type canvas_item;

// The landscape texture used as a mask
uniform sampler2D mask_texture : source_color;
uniform vec2 mask_offset = vec2(0.0);  // Landscape position offset
uniform vec2 mask_scale = vec2(1.0);   // If landscape is scaled

// Key color in the mask - where this appears, discard starfield
uniform vec3 key_color : source_color = vec3(0.298, 0.298, 0.498);
uniform float key_threshold = 0.02;

void fragment() {
    // Sample the mask (landscape) at screen position adjusted for its transform
    vec2 mask_uv = (SCREEN_UV - mask_offset) / mask_scale;
    vec4 mask = texture(mask_texture, mask_uv);

    // If mask has key color at this position, discard starfield (show backdrop)
    if (mask.a > 0.01 && distance(mask.rgb, key_color) < key_threshold) {
        discard;
    }

    // Otherwise draw the starfield normally
    COLOR = texture(TEXTURE, UV);
}

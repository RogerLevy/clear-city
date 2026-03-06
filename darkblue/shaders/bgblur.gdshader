shader_type canvas_item;

uniform float radius : hint_range(0.0, 20.0) = 10.0;
uniform float expansion : hint_range(0.0, 100.0) = 20.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.3;

// Pseudo-random noise function for dithering
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
    VERTEX += (UV * 2.0 - 1.0) * expansion;
}

void fragment() {
    vec2 ps = TEXTURE_PIXEL_SIZE;
    vec4 col = vec4(0.0);
    float total_weight = 0.0;

    for (float x = -radius; x <= radius; x++) {
        for (float y = -radius; y <= radius; y++) {
            float weight = exp(-0.5 * (x * x + y * y) / (radius * radius / 4.0));
            col += texture(TEXTURE, UV + vec2(x, y) * ps) * weight;
            total_weight += weight;
        }
    }
    
    vec4 final_color = col / total_weight;
    
    // Apply dithering to hide banding
    // (1.0 / 255.0) is the size of one 8-bit color step
    float noise = (random(FRAGCOORD.xy) - 0.5) * (1.0 / 255.0) * dither_strength;
    final_color.rgb += noise;
    
    COLOR = final_color;
}
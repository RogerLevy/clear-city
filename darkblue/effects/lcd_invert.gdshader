shader_type canvas_item;

uniform float inversion : hint_range(0.0, 1.0) = 0.5;
uniform float tilt_strength : hint_range(0.0, 1.0) = 0.5;  // How much vertical position affects inversion
uniform float tilt_center : hint_range(0.0, 1.0) = 0.5;    // Vertical center point (0=top, 1=bottom)
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// Gradient map colors (dark to light for inverted LCD look)
uniform vec4 color_dark : source_color = vec4(0.75, 0.78, 0.65, 1.0);   // Greenish light
uniform vec4 color_mid : source_color = vec4(0.45, 0.50, 0.35, 1.0);    // Murky green
uniform vec4 color_light : source_color = vec4(0.15, 0.20, 0.12, 1.0);  // Dark green/brown

// 4x4 Bayer matrix for ordered dithering
const mat4 BAYER = mat4(
    vec4( 0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0),
    vec4(12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0),
    vec4( 3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0),
    vec4(15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0)
);

float get_bayer(vec2 coord) {
    int x = int(mod(coord.x, 4.0));
    int y = int(mod(coord.y, 4.0));
    return BAYER[y][x];
}

// Noise for additional temporal/spatial variation
float noise(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec4 original = texture(screen_texture, SCREEN_UV);

    // Calculate vertical tilt effect
    float vert_offset = (SCREEN_UV.y - tilt_center) * 2.0;  // -1 to 1 range from center
    float tilt_factor = abs(vert_offset) * tilt_strength;
    float local_inversion = clamp(inversion + tilt_factor * sign(vert_offset), 0.0, 1.0);

    // Calculate luminance, scaled so #22228b=0% and #d1d1b2=100%
    float raw_lum = dot(original.rgb, vec3(0.299, 0.587, 0.114));
    float lum = clamp((raw_lum - 0.18) / 0.626, 0.0, 1.0);

    // Inversion flips luminance: bright source -> dark destination, vice versa
    float dest_pos = 1.0 - lum;

    // As inversion increases, pixel travels through gradient toward destination
    // At inversion=0: original color, at inversion=1: gradient[dest_pos]
    float current_pos = dest_pos * local_inversion;

    // Sample gradient at current position along the journey
    vec3 gradient_color;
    if (current_pos < 0.5) {
        gradient_color = mix(color_dark.rgb, color_mid.rgb, current_pos * 2.0);
    } else {
        gradient_color = mix(color_mid.rgb, color_light.rgb, (current_pos - 0.5) * 2.0);
    }

    // Blend from original toward gradient color based on inversion
    vec3 result = mix(original.rgb, gradient_color, local_inversion);

    // Apply dithering to prevent banding
    // Combine Bayer pattern with noise for best results
    float bayer = get_bayer(FRAGCOORD.xy);
    float n = noise(FRAGCOORD.xy + vec2(local_inversion * 100.0, 0.0));
    float dither = mix(bayer, n, 0.3) - 0.5;

    // Scale dither by color step size (1/255) and apply
    result += dither * (2.0 / 255.0);

    COLOR.rgb = result;
    COLOR.a = original.a;
}

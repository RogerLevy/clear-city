shader_type canvas_item;

uniform float fill_radius : hint_range(0.0, 1.0) = 0.0;
uniform float cutout_radius : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center) * 2.0; // 0 at center, 1 at edge

    // Draw if within fill radius but outside cutout radius
    if (dist <= fill_radius && dist >= cutout_radius) {
        // COLOR already contains modulate from vertex stage
    } else {
        COLOR = vec4(0.0);
    }
}

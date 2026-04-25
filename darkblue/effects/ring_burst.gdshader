shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float thickness : hint_range(0.0, 0.5) = 0.1;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center) * 2.0; // 0 at center, 1 at edge

    float inner = radius - thickness;
    float outer = radius;

    if (dist >= inner && dist <= outer) {
        // Inside the ring
    } else {
        COLOR = vec4(0.0);
    }
}

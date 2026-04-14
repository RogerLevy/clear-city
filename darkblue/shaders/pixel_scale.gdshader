shader_type canvas_item;
render_mode blend_disabled;

// Bias toward dark (-1) or light (+1) when scaling
uniform float bias : hint_range(-1.0, 1.0) = -0.3;
// Push colors away from midpoint (0.0 = no effect, 1.0 = full push)
uniform float contrast : hint_range(0.0, 3.0) = 0.0;
uniform vec3 dark_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 light_color : source_color = vec3(1.0, 1.0, 1.0);
// Color key to replace with punch-through
uniform vec3 key_color : source_color = vec3(0.298, 0.298, 0.498);
uniform float key_threshold = 0.02;

void fragment() {
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 pixel = UV * tex_size;
    vec2 pixel_floor = floor(pixel);
    vec2 frac = pixel - pixel_floor;

    // Sample the 4 neighboring pixels
    vec2 uv00 = (pixel_floor + vec2(0.5)) / tex_size;
    vec2 uv10 = (pixel_floor + vec2(1.5, 0.5)) / tex_size;
    vec2 uv01 = (pixel_floor + vec2(0.5, 1.5)) / tex_size;
    vec2 uv11 = (pixel_floor + vec2(1.5, 1.5)) / tex_size;

    vec4 c00 = texture(TEXTURE, uv00);
    vec4 c10 = texture(TEXTURE, uv10);
    vec4 c01 = texture(TEXTURE, uv01);
    vec4 c11 = texture(TEXTURE, uv11);

    // Compute luminance for each sample
    float l00 = dot(c00.rgb, vec3(0.299, 0.587, 0.114));
    float l10 = dot(c10.rgb, vec3(0.299, 0.587, 0.114));
    float l01 = dot(c01.rgb, vec3(0.299, 0.587, 0.114));
    float l11 = dot(c11.rgb, vec3(0.299, 0.587, 0.114));

    // Bilinear luminance
    float lum = mix(mix(l00, l10, frac.x), mix(l01, l11, frac.x), frac.y);

    // Find darkest and lightest neighbors
    float min_lum = min(min(l00, l10), min(l01, l11));
    float max_lum = max(max(l00, l10), max(l01, l11));

    vec4 dark_pixel;
    if (l00 == min_lum) dark_pixel = c00;
    else if (l10 == min_lum) dark_pixel = c10;
    else if (l01 == min_lum) dark_pixel = c01;
    else dark_pixel = c11;

    vec4 light_pixel;
    if (l00 == max_lum) light_pixel = c00;
    else if (l10 == max_lum) light_pixel = c10;
    else if (l01 == max_lum) light_pixel = c01;
    else light_pixel = c11;

    // Interpolate between dark and light based on luminance, shifted by bias
    // bias < 0 shifts toward dark, bias > 0 shifts toward light
    float t = clamp((lum - min_lum) / max(max_lum - min_lum, 0.001) + bias, 0.0, 1.0);
    vec4 tex = mix(dark_pixel, light_pixel, t);

    // Push colors away from midpoint toward dark/light
    if (contrast > 0.0) {
        float dark_lum = dot(dark_color, vec3(0.299, 0.587, 0.114));
        float light_lum = dot(light_color, vec3(0.299, 0.587, 0.114));
        float mid_lum = (dark_lum + light_lum) * 0.5;
        float pixel_lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

        if (pixel_lum > mid_lum) {
            // Push toward light
            float t = (pixel_lum - mid_lum) / max(light_lum - mid_lum, 0.001);
            tex.rgb = mix(tex.rgb, light_color, t * contrast);
        } else {
            // Push toward dark
            float t = (mid_lum - pixel_lum) / max(mid_lum - dark_lum, 0.001);
            tex.rgb = mix(tex.rgb, dark_color, t * contrast);
        }
    }

    // Handle transparency
    if (tex.a < 0.01) {
        discard;
    }

    // Handle key color punch-through
    if (distance(tex.rgb, key_color) < key_threshold) {
        COLOR = vec4(0.0);
    } else {
        COLOR = tex;
    }
}

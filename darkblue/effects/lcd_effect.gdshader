shader_type canvas_item;
render_mode blend_premul_alpha;

uniform sampler2D game_frame : filter_nearest;
uniform sampler2D prev_output : filter_nearest;
uniform float fade_in_speed : hint_range(0.0, 1.0) = 0.3;
uniform float fade_out_speed : hint_range(0.0, 1.0) = 0.001;

void fragment() {
	vec4 game = texture(game_frame, UV);
	vec4 prev = texture(prev_output, UV);

    vec4 up = mix(prev, game, fade_in_speed);      // ramp up when game brighter
    vec4 hold = prev * (1.0 - fade_out_speed);     // slow decay when game gone
    COLOR = max(up, hold);
}

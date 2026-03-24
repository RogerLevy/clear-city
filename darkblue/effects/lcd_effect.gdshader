shader_type canvas_item;
render_mode blend_premul_alpha;

uniform sampler2D game_frame : filter_nearest;
uniform sampler2D prev_output : filter_nearest;
uniform float fade_in_speed : hint_range(0.01, 1.0) = 0.2;
uniform float fade_out_speed : hint_range(0.01, 1.0) = 0.1;

void fragment() {
	vec4 game = texture(game_frame, UV);
	vec4 prev = texture(prev_output, UV);

	if (game.a >= prev.a) {
		// Fading in: approach game color and alpha
		COLOR = vec4(game.rgb, mix(prev.a, game.a, fade_in_speed));
	} else {
		// Fading out: keep color, just reduce alpha
		COLOR = vec4(prev.rgb, prev.a * (1.0 - fade_out_speed));
	}
}

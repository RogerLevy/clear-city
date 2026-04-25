shader_type canvas_item;
render_mode blend_premul_alpha;

uniform sampler2D game_frame : filter_nearest;
uniform sampler2D prev_output : filter_nearest;
uniform float fade_in_speed : hint_range(0.0, 1.0) = 0.3;
uniform float fade_out_speed : hint_range(0.0, 1.0) = 0.2;
uniform float alpha_bias : hint_range(0.1, 4.0) = 1.0;

void fragment() {
	vec4 game = texture(game_frame, UV);
	float signal = pow(dot(game.rgb, vec3(0.299, 0.587, 0.114)), alpha_bias);
	float prev = texture(prev_output, UV).r;

	float up = mix(prev, signal, fade_in_speed);
	float hold = prev * (1.0 - fade_out_speed);
	float intensity = max(up, hold);
	COLOR = vec4(intensity, intensity, intensity, 1.0);
}

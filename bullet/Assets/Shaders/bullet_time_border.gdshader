shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float contrast : hint_range(0.5, 1.5) = 1.0;
uniform vec3 sepia_bias = vec3(1.06, 1.0, 0.82);

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec3 sepia = vec3(
		dot(screen_color.rgb, vec3(0.393, 0.769, 0.189)),
		dot(screen_color.rgb, vec3(0.349, 0.686, 0.168)),
		dot(screen_color.rgb, vec3(0.272, 0.534, 0.131))
	);
	sepia *= sepia_bias;
	sepia = clamp((sepia - 0.5) * contrast + 0.5, 0.0, 1.0);
	COLOR = vec4(mix(screen_color.rgb, sepia, intensity), screen_color.a);
}

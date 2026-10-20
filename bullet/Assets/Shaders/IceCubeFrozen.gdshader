shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 screen_color = COLOR;
	vec3 shading = vec3(0.0,0.5,0.6);
	COLOR = vec4(mix(screen_color.rgb, shading, intensity), screen_color.a/3.0);
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

shader_type canvas_item;

// 0 keeps the original brightness; 1 makes decorations black.
uniform float darken_amount : hint_range(0.0, 1.0, 0.01) = 0.25;

void fragment() {
	COLOR.rgb *= 1.0 - darken_amount;
}

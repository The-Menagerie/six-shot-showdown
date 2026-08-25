shader_type canvas_item;
 
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
 
void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
    vec4 sprite = texture(TEXTURE, UV);
 
    float alpha = sprite.a;
    alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
    alpha = min(alpha, 1.0);
 
    COLOR = mix(vec4(outline_color.rgb, alpha), sprite, sprite.a);
}
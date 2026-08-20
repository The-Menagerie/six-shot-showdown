shader_type canvas_item;
 
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float scanline_freq : hint_range(100.0, 1000.0) = 400.0;
uniform float curvature : hint_range(0.0, 0.5) = 0.1;
 
void fragment() {
    vec2 uv = UV;
    vec2 cc = uv - 0.5;
    float dist = dot(cc, cc);
    uv = uv + cc * dist * curvature;
 
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        COLOR = vec4(0.0);
    } else {
        vec4 color = texture(TEXTURE, uv);
        float scanline = sin(uv.y * scanline_freq) * 0.5 + 0.5;
        color.rgb *= 1.0 - scanline_intensity * scanline;
        COLOR = color;
    }
}
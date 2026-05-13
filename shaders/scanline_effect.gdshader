shader_type canvas_item;

// Cyberpunk scanline effect
uniform float u_scanline_count: hint_range(50.0, 500.0) = 100.0;
uniform float u_intensity: hint_range(0.0, 1.0) = 0.3;
uniform float u_speed: hint_range(0.0, 10.0) = 2.0;
uniform float u_flicker: hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    // Scanlines
    float scanline = sin((UV.y * u_scanline_count + TIME * u_speed) * 3.14159 * 2.0);
    scanline = (scanline * 0.5 + 0.5) * u_intensity;
    scanline = mix(1.0, scanline, 0.5);
    
    // Subtle flicker
    float flicker = 1.0 - u_flicker * (sin(TIME * 20.0) * 0.5 + 0.5);
    
    // Apply effect
    COLOR = vec4(tex.rgb * scanline * flicker, tex.a);
}
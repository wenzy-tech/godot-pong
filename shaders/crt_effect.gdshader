shader_type canvas_item;

// CRT/Scanline effect for retro cyberpunk look

uniform float u_scanline_intensity: hint_range(0.0, 1.0) = 0.15;
uniform float u_scanline_count: hint_range(100.0, 800.0) = 400.0;
uniform float u_vignette_intensity: hint_range(0.0, 1.0) = 0.3;
uniform float u_chromatic_aberration: hint_range(0.0, 5.0) = 1.5;

void fragment() {
    vec2 uv = UV;
    vec4 tex = texture(TEXTURE, uv);
    
    // Scanlines
    float scanline = sin(uv.y * u_scanline_count * 3.14159 * 2.0);
    scanline = (scanline * 0.5 + 0.5);
    scanline = 1.0 - (1.0 - scanline) * u_scanline_intensity;
    
    // Chromatic aberration (subtle RGB split)
    float aberration = u_chromatic_aberration * 0.001;
    float r = texture(TEXTURE, uv + vec2(aberration, 0.0)).r;
    float g = texture(TEXTURE, uv).g;
    float b = texture(TEXTURE, uv - vec2(aberration, 0.0)).b;
    vec3 color = vec3(r, g, b);
    
    // Apply scanlines
    color *= scanline;
    
    // Vignette
    vec2 center = uv - 0.5;
    float dist = length(center);
    float vignette = 1.0 - smoothstep(0.4, 0.8, dist) * u_vignette_intensity;
    color *= vignette;
    
    // Subtle noise/grain
    float noise = fract(sin(dot(uv * TIME, vec2(12.9898, 78.233))) * 43758.5453);
    color += (noise - 0.5) * 0.02;
    
    // Flicker
    float flicker = 1.0 - 0.02 * sin(TIME * 60.0);
    color *= flicker;
    
    COLOR = vec4(color, tex.a);
}
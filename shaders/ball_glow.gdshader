shader_type canvas_item;

// Ball glow shader - creates neon glow effect
uniform float u_pulse_speed: hint_range(0.0, 10.0) = 4.0;
uniform float u_glow_size: hint_range(0.0, 1.0) = 0.3;
uniform vec4 u_ball_color: hint_color = vec4(0.0, 1.0, 0.8, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    // Pulsing
    float pulse = 1.0 + sin(TIME * u_pulse_speed) * u_glow_size;
    
    // Glow from center
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center);
    float glow = 1.0 - smoothstep(0.0, 0.5 * pulse, dist);
    
    // Combine texture with glow
    vec3 color = tex.rgb + u_ball_color.rgb * glow * 0.8;
    
    COLOR = vec4(color, tex.a);
}
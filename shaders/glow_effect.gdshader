shader_type canvas_item;

uniform float u_glow_intensity: hint_range(0.0, 2.0) = 1.5;
uniform float u_glow_radius: hint_range(0.0, 50.0) = 20.0;
uniform vec4 u_glow_color: hint_color = vec4(0.0, 1.0, 0.8, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    // Pulsing glow based on time
    float pulse = 0.8 + sin(TIME * 4.0) * 0.2;
    
    // Outer glow
    float glow = u_glow_intensity * pulse;
    
    // Mix original texture with glow color
    vec3 glow_effect = u_glow_color.rgb * glow * 0.5;
    vec3 final_color = tex.rgb + glow_effect;
    
    COLOR = vec4(final_color, tex.a);
}
shader_type canvas_item;

uniform sampler2D emission_mask;
uniform vec3  emission_color : source_color = vec3(0.0, 0.0, 0.0); // sRGB->linear in Godot 4
uniform float emission_strength = 0.8;  // start low; bloom will amplify
uniform float base_darken       = 0.5;  // 0..1: how much to dim base under glow
uniform float glow_alpha        = 1.0;  // alpha contribution of the glow

// Scale down uniformly if any channel would exceed 1.0, preserving hue.
vec3 hue_preserve_cap(vec3 c) {
    float mx = max(max(c.r, c.g), c.b);
    return (mx > 1.0) ? (c / mx) : c;
}

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    float m   = texture(emission_mask, UV).r;

    // colored glow energy (keep it modest; bloom handles the halo)
    vec3 glow = emission_color * (emission_strength * m);

    // let base step out of the way so color isn't washed to white
    vec3 base_rgb = base.rgb * (1.0 - m * base_darken);

    // combine and cap to keep color
    vec3 rgb = base_rgb + glow;
    rgb = hue_preserve_cap(rgb);

    // crucial: allow glow to show over transparent base
    float a = max(base.a, m * glow_alpha);

    COLOR = vec4(rgb, a);
}

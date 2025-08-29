shader_type spatial;

uniform sampler2D caustic_texture : hint_default_white;
uniform sampler2D distortion : hint_default_white;

uniform vec4 color : source_color;
uniform vec2 center = vec2(0.5);
uniform float speed : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float zoom : hint_range(0.0, 5.0, 0.1) = 2.0;
uniform float tile : hint_range(0.0, 5.0, 0.1) = 1.0;
uniform float caustic_strength : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float distortion_strength: hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float distortion_speed: hint_range(0.0, 1.0, 0.1) = 0.1;

vec2 distort_uv(vec2 uv) {
    return uv + texture(distortion, uv + TIME * distortion_speed).r * distortion_strength - distortion_strength / 2.0;
}

vec2 polar_coords(vec2 uv) {
    vec2 diff = uv - center;
    float r = length(diff);
    float theta = atan(diff.y, diff.x) / TAU;

    return vec2(r * zoom, theta * tile);
}

void fragment() {
    vec4 distort = texture(distortion, UV + TIME * distortion_speed);
    vec2 polar = polar_coords(distort_uv(UV));
    vec4 tex = texture(caustic_texture, vec2(polar.x - TIME * speed, polar.y));

    float fade = (1.0 - smoothstep(0.5, 1.0, polar.x)) / 2.0 * caustic_strength;
    float blur = smoothstep(0.0, 0.4, polar.x);

    ALBEDO = mix(vec3(1.0), mix(color.rgb, tex.rgb, fade), blur);
    ALPHA = color.a;
    ROUGHNESS = 1.35;
}

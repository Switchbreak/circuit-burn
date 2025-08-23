shader_type spatial;

render_mode cull_disabled, depth_prepass_alpha;

uniform sampler2D water : source_color;
uniform sampler2D normal : hint_normal;
uniform sampler2D profile : hint_default_white;

uniform float stretch : hint_range(0, 25) = 3.0;
uniform float speed : hint_range(0, 1) = 0.2;
uniform float displace_amount : hint_range(0.0, 0.5, 0.01) = 0.15;
uniform float shadow_threshold : hint_range(0, 1) = 0.5;

uniform vec2 ripple_strength = vec2(0.2, 0.02);
uniform vec2 ripple_frequency = vec2(4.0, 5.0);
uniform vec2 ripple_speed = vec2(5.0, 10.0);

void fragment() {
    vec2 displace = texture(water, vec2(UV.x, TIME * speed / stretch)).xy * displace_amount;
    vec4 color = texture(water, vec2(UV.x, UV.y / stretch - TIME * speed) + displace);
    float gradient = texture(profile, vec2(UV.x, 0.5)).r;

    bool is_shadow_pass = PROJECTION_MATRIX[2][3] == 0.0;
    if (is_shadow_pass && color.g < shadow_threshold) {
        discard;
    } else {
       	ALBEDO = color.rgb;
        ALPHA = color.g * gradient;
        NORMAL_MAP = texture(normal, vec2(UV.x, UV.y / stretch - TIME * speed)).rgb;
        ROUGHNESS = 0.13;
    }
}

void vertex() {
    VERTEX.z += ripple_strength.x * sin(ripple_frequency.x * VERTEX.x + ripple_speed.x * TIME) + ripple_strength.y * sin(ripple_frequency.y * VERTEX.y + ripple_speed.y * TIME);
}

void light() {
    float diffuse = abs(dot(NORMAL, LIGHT));
    
    DIFFUSE_LIGHT += diffuse * ALBEDO * LIGHT_COLOR;
}
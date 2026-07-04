shader_type canvas_item;

uniform float whiten_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    vec3 white_color = vec3(1.0, 1.0, 1.0);
    COLOR = vec4(mix(texture_color.rgb, white_color, whiten_intensity), texture_color.a);
}
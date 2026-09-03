shader_type spatial;

const float S16_MAX = 32768.0;

uniform sampler2D albedo_texture: source_color, repeat_disable;

uniform vec4 override_color: source_color = vec4(0);

void fragment() {
	vec2 albedo_texture_size = vec2(textureSize(albedo_texture, 0));
	vec2 albedo_uv = UV * S16_MAX / albedo_texture_size;
	vec4 albedo = texture(albedo_texture, albedo_uv);
	
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	
	ALBEDO = mix(albedo.rgb, override_color.rgb, override_color.a);
	ALPHA = albedo.a;
	EMISSION = ALBEDO * ALPHA;
}

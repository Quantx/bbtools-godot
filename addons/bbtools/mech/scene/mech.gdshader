shader_type spatial;

const uint paint_colors_count = 12u;
uniform vec4 paint_colors[paint_colors_count] : source_color;

uniform sampler2D albedo_texture : source_color, repeat_disable;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float irradiance_scale : hint_range(0.0, 1.0, 0.01) = 0.1;

varying smooth vec4 paint_color;

// COLOR.r determines the alpha of the paint color
// COLOR.g is unused
// COLOR.b determines the specular reflection
// COLOR.a is an integer 0-255 index into the paint_colors array

void vertex() {
	uint paint_index = min(uint(COLOR.a * 255.0), paint_colors_count - 1u);
	paint_color = paint_colors[paint_index];
	paint_color.a *= COLOR.r;
}

void fragment() {
	vec4 albedo = texture(albedo_texture, UV);
	ALBEDO = albedo.rgb * mix(vec3(1.0), 6.0 * paint_color.rgb, paint_color.a);
	ALPHA = albedo.a;
	
	SPECULAR = COLOR.b;
	
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}

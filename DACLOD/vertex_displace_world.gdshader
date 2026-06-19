// NOTE: Shader automatically converted from Godot Engine 4.6.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_height : source_color,filter_linear_mipmap;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform float HEIGHT_SCALE = 500.0;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
varying vec2 scale_uv;
varying vec3 world_pos;


vec4 sample_middle_of_pixel(sampler2D tex, vec2 uv) {
	// Sample from exact middle of each pixel to ensure same result as in collision shape calculation.
	vec2 texture_coords_in_px = floor(uv * (vec2(textureSize(tex, 0)) - 1.0));
	texture_coords_in_px += 0.5;
	
	// Put coordinates back into UV space and sample texture.
	vec2 texture_position = clamp(texture_coords_in_px / vec2(textureSize(tex,0)), 0.0, 1.0);
	return texture(tex, texture_position);
}
void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	
	
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (VERTEX.y > -1.0)
		VERTEX.y =  500.0*sample_middle_of_pixel(texture_height, vec2(world_pos.x/4096.0,world_pos.z/4096.0)).r;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, world_pos.xz/4096.0);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
}

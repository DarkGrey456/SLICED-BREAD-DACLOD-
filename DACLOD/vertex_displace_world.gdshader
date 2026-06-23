// NOTE: Shader automatically converted from Godot Engine 4.6.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec4 uv_scale = vec4(9.0,18.0, 9.0, 2.0);
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normal : source_color, repeat_enable;
uniform sampler2D texture_height : source_color;//,filter_linear_mipmap;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D alb_h_1: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D alb_h_2: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D alb_h_3: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D alb_h_4: source_color, filter_linear_mipmap, repeat_enable;

uniform sampler2D norm_r_1: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D norm_r_2: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D norm_r_3: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D norm_r_4: source_color, filter_linear_mipmap, repeat_enable;

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

// Unpack from texture -> XYZ. Texture is between 0 and 1, normals are -1 to 1. Negate Z because OpenGL uses Y-up normal maps.
vec3 unpack_normal(vec4 rgba) {
	vec3 n = rgba.xzy * 2.0 - vec3(1.0);
	// Had to negate Z because it comes from Y in the normal map,
	// and OpenGL-style normal maps are Y-up.
	n.z *= -1.0;
	return n;
}

varying vec2 uv_offset;

void vertex() {
	UV =   UV * uv1_scale.xy + uv1_offset.xy;
	
	
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (VERTEX.y > -1.0)
		VERTEX.y =  HEIGHT_SCALE*texture(texture_height, vec2(world_pos.x/4096.0,world_pos.z/4096.0)).r;
	
	vec3 norm = unpack_normal( texture(texture_normal, vec2(world_pos.x/4096.0,world_pos.z/4096.0))).rgb;	
	norm.b = ( 1.0 - norm.r*norm.r - norm.g*norm.g);

	NORMAL = norm;//normalize(norm);// (VIEW * vec4(norm, 1.0)).xyz;
	
		float h1 =texture(alb_h_1, UV*uv_scale.x).a; 
		float h2 =texture(alb_h_2, UV*uv_scale.y).a; 
		float h3 =texture(alb_h_3, UV*uv_scale.z).a; 
		float h4 =texture(alb_h_4, UV*uv_scale.w).a; 		
		vec4 albedo_tex = texture(texture_albedo, world_pos.xz/4096.0);
	//if ( albedo_tex.g > 0.5)
	{
		// Height: Enabled
		vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT, -BINORMAL , NORMAL));
		float hval = (albedo_tex.r* h1 + albedo_tex.g * h4 + albedo_tex.b * h2 + 0.25*(1.0-albedo_tex.g)* h3);
		//float depth = 1.0 - hval;
		//vec2 ofs = UV - view_dir.xy * depth * 1.0 * 0.01;
		//uv_offset = ofs;
		VERTEX.y += 2.5*hval;// 5.0 * hval * NORMAL - 2.5 * NORMAL;
	}			
	
}



void fragment() {
	vec2 base_uv = UV;
	bool un_shaded = false;
	vec4 albedo_tex = texture(texture_albedo, world_pos.xz/4096.0);
	if( un_shaded ){
		ALBEDO = albedo_tex.rgb;
	}
	else {

		vec4 alb1 =texture(alb_h_1, UV*uv_scale.x); 
		vec4 alb2 =texture(alb_h_2, UV*uv_scale.y); 
		vec4 alb3 =texture(alb_h_3, UV*uv_scale.z); 
		vec4 alb4 =texture(alb_h_4, UV*uv_scale.w); 
		vec4 n1 =texture(norm_r_1, UV*uv_scale.x); 
		vec4 n2 =texture(norm_r_2, UV*uv_scale.y); 
		vec4 n3 =texture(norm_r_3, UV*uv_scale.z); 
		vec4 n4 =texture(norm_r_4, UV*uv_scale.w); 
		float roughness_tex = albedo_tex.r* n1.a + albedo_tex.g * n4.a + albedo_tex.b * n2.a + 0.25*(1.0-albedo_tex.g)* n3.a;
		ROUGHNESS = roughness_tex * roughness*2.5;	
		//n1 = vec4(unpack_normal(n1),1.0);
		//n2 = vec4(unpack_normal(n2),1.0);
		//n3 = vec4(unpack_normal(n3),1.0);
		//n4 = vec4(unpack_normal(n4),1.0);
		NORMAL_MAP = normalize(albedo_tex.r*n1.rgb + albedo_tex.g * n4.rgb + albedo_tex.b * n2.rgb + 0.25*(1.0-albedo_tex.g)* n3.rgb) /2.0;
		ALBEDO =  albedo_tex.r * alb1.rgb + albedo_tex.g * alb4.rgb + albedo_tex.b * alb2.rgb + 0.25*(1.0-albedo_tex.g)* alb3.rgb + 0.1*albedo_tex.b;

	}
	//ALBEDO *= 0.5;
	//float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	//METALLIC = metallic_tex * metallic;
	//SPECULAR = specular;



}

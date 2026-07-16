// NOTE: Shader automatically converted from Godot Engine 4.6.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform int channel_for_splat = 1;
uniform vec4 uv_scale = vec4(9.0,18.0, 9.0, 2.0);
uniform vec4 albedo : source_color;
uniform sampler2D splat_tex :  repeat_enable;
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

uniform sampler2D alb_h_1: source_color,filter_linear_mipmap, repeat_enable;
//uniform sampler2D alb_h_2: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D alb_h_3:  source_color,filter_linear_mipmap, repeat_enable;
//uniform sampler2D alb_h_4: source_color, filter_linear_mipmap, repeat_enable;

uniform sampler2D norm_r_1:  filter_linear_mipmap, repeat_enable;
//uniform sampler2D norm_r_2: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D norm_r_3: filter_linear_mipmap, repeat_enable;
//uniform sampler2D norm_r_4: source_color, filter_linear_mipmap, repeat_enable;

uniform float HEIGHT_SCALE = 500.0;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

// these can be used for the calculation that attempts to snap the vertices
// to the lower lod.
uniform int lod;
uniform vec2 grid_loc;
uniform vec2 player_grid_loc;

varying vec2 scale_uv;
varying vec3 world_pos;

// from hTerrain
// not used ... maybe in the future ...
vec4 get_depth_blended_weights(vec4 splat, vec4 bumps) {
	float dh = 0.2;

	vec4 h = bumps + splat;

	h *= smoothstep(0, 0.05, splat);

	vec4 d = h + dh;
	d.r -= max(h.g, max(h.b, h.a));
	d.g -= max(h.r, max(h.b, h.a));
	d.b -= max(h.g, max(h.r, h.a));
	d.a -= max(h.g, max(h.b, h.r));

	return clamp(d, 0, 1);
}

// from Simple Terrain ... not used, maybe in the future
vec4 sample_middle_of_pixel(sampler2D tex, vec2 uv) {
	// Sample from exact middle of each pixel to ensure same result as in collision shape calculation.
	vec2 texture_coords_in_px = floor(uv * (vec2(textureSize(tex, 0)) - 1.0));
	texture_coords_in_px += 0.5;
	
	// Put coordinates back into UV space and sample texture.
	vec2 texture_position = clamp(texture_coords_in_px / vec2(textureSize(tex,0)), 0.0, 1.0);
	return texture(tex, texture_position);
}

// from hTerrain
// Unpack from texture -> XYZ. Texture is between 0 and 1, normals are -1 to 1. Negate Z because OpenGL uses Y-up normal maps.
// Note: I think Godot may have started using this technique internally, anyway setting NORMAL_MAP seems to work
// without unpacking for ground textures ... the Terrain itself uses dynamically computed normals
// the problem is clearly visible with or without this function if the Normal map is used
vec3 unpack_normal(vec4 rgba) {
	vec3 n = rgba.xzy * 2.0 - vec3(1.0);
	// Had to negate Z because it comes from Y in the normal map,
	// and OpenGL-style normal maps are Y-up.
	n.z *= -1.0;
	return n;
}


float get_splat_color(vec4 color){
	if (channel_for_splat == 0) return color.r;
	if (channel_for_splat == 1) return color.g;
	if (channel_for_splat == 2) return color.b;
	return color.a;
}

void vertex() {
	
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	UV = vec2(world_pos.xz/128.0 );//- floor(world_pos.xz/127.0 )) ;

	float H0 = HEIGHT_SCALE*texture(texture_height, vec2((world_pos.x-1.0)/4096.0,world_pos.z/4096.0)).r;
	float H1 = HEIGHT_SCALE*texture(texture_height, vec2((world_pos.x+1.0)/4096.0,world_pos.z/4096.0)).r;
	float H2 = HEIGHT_SCALE*texture(texture_height, vec2((world_pos.x)/4096.0,(world_pos.z-1.0)/4096.0)).r;
	float H3 = HEIGHT_SCALE*texture(texture_height, vec2((world_pos.x)/4096.0,(world_pos.z+1.0)/4096.0)).r;
	//vec3 v1 = vec3(world_pos.x - 1.0, H0, world_pos.z);
	//vec3 v2 = vec3(world_pos.x + 1.0, H1, world_pos.z);
	//vec3 v3 = vec3(world_pos.x, H2, world_pos.z - 1.0);
	/*vec3 v4 = vec3(world_pos.x, H3, world_pos.z + 1.0);
	vec3 VA = vec3( 2.0, H1 - H0, 0.0 );
	vec3 VB = vec3( 0.0, H3 - H2, 2.0);
	vec3 VX = cross(VA,VB); */
	// i j k 
	// 2 HA 0     = i (2 HA) - j (4) + k (2 HB)
	// 0 HB 2
	
	NORMAL = -normalize(vec3(2.0*(H1 - H0), -4.0, 2.0*(H3-H2) ));//vec3(H0 - H1, 0.8, H2-H3));
	
	float vy = VERTEX.y;
	
	
	if( COLOR.r == 1.0 && COLOR.g == 0.0 && COLOR.b == 0.0){
		if (VERTEX.x < (0.0 + 0.25)  ){
			VERTEX.y += (H2 + H3)/2.0; ;//  mix( H2, H3, 0.5) * HEIGHT_SCALE;
		}
		if (VERTEX.x > 128.0-0.25){
			VERTEX.y =(H2 + H3)/2.0;//mix( H2, H3, 0.5) * HEIGHT_SCALE;
		}
		if (VERTEX.z < (0.0 + 0.25)  ){
			VERTEX.y = (H0 + H1)/2.0;//mix( H0, H1, 0.5) * HEIGHT_SCALE;
		}
		if (VERTEX.z > 128.0-0.25){
			VERTEX.y = (H0 + H1)/2.0;//mix( H0, H1, 0.5) * HEIGHT_SCALE;
		}		
	}
	else{
		VERTEX.y +=  HEIGHT_SCALE*texture(texture_height, vec2(world_pos.x/4096.0,world_pos.z/4096.0)).r;
	}
	float h1 =texture(alb_h_1, UV*uv_scale.x).a; 
	//float h2 =texture(alb_h_2, UV*uv_scale.y).a; 
	float h3 =texture(alb_h_3, UV*uv_scale.z).a; 
	//float h4 =texture(alb_h_4, UV*uv_scale.w).a; 		
	vec4 splat_map = texture(splat_tex, world_pos.xz/4096.0);
		
	//vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT, -BINORMAL , NORMAL));
	float splat_color = get_splat_color(splat_map);
	float hval = (splat_color* h1 + (1.0-splat_color)* h3);

	// this function ,must be the same as the function that generates the collisions
	// the vy check is for the terrain tiles *with* skirts ... not currently used.
	if( COLOR.r == 1.0 && COLOR.g == 0.0 && COLOR.b == 0.0){
		float S0 = texture(splat_tex, vec2((world_pos.x-1.0)/4096.0,world_pos.z/4096.0)).g;
		float S1 = texture(splat_tex, vec2((world_pos.x+1.0)/4096.0,world_pos.z/4096.0)).g;
		float S2 = texture(splat_tex, vec2((world_pos.x)/4096.0,(world_pos.z-1.0)/4096.0)).g;
		float S3 = texture(splat_tex, vec2((world_pos.x)/4096.0,(world_pos.z+1.0)/4096.0)).g;		
		float splat_col = 0.0;
		if (VERTEX.x < (0.0 + 0.25)  ){
			splat_col = (S2 + S3)/2.0; ;//  mix( H2, H3, 0.5) * HEIGHT_SCALE;
		}
		if (VERTEX.x > 128.0-0.25){
			splat_col =(S2 + S3)/2.0;//mix( H2, H3, 0.5) * HEIGHT_SCALE;
		}
		if (VERTEX.z < (0.0 + 0.25)  ){
			splat_col = (S0 + S1)/2.0;//mix( H0, H1, 0.5) * HEIGHT_SCALE;
		}
		if (VERTEX.z > 128.0-0.25){
			 splat_col = (S0 + S1)/2.0;//mix( H0, H1, 0.5) * HEIGHT_SCALE;
		}				
			
	float hval_snap = (splat_col* h1 + (1.0-splat_col)* h3);
	VERTEX +=  5.0 * hval_snap * NORMAL;// - 2.5 * NORMAL;	
	}
	else{
		if (vy > -0.5)
			VERTEX +=  5.0 * hval * NORMAL;// - 2.5 * NORMAL;			
	}

	COLOR.r = splat_map.r;
	COLOR.g = splat_map.g;
	COLOR.b = splat_map.b;
}

// Change of basis https://www.youtube.com/watch?v=P2LTAUO1TdA
// unused function from SimpleTerrain ... 
vec3 apply_normal_basis(vec3 n1, vec3 n2)
{
	vec3 up = n1;
	vec3 right = vec3(n1.y, -n1.z, n1.x);
	vec3 forward = vec3(n1.x, -n1.z, n1.y);
	vec3 change_of_basis = n2.x*right + n2.y*up + n2.z*forward;
	
	// Prevent n2 rotated from pointing away from n1
	//change_of_basis.y = max(change_of_basis.y, 0.0);
	
    return normalize(change_of_basis);
}

void fragment() {
	vec2 base_uv = UV;
	//bool un_shaded = false;
	
	/*if( un_shaded ){
		vec4 splat_tex = texture(texture_albedo, world_pos.xz/4096.0);
		ALBEDO = splat_tex.rgb;
	}
	else {*/

	vec4 alb1 =texture(alb_h_1, UV*uv_scale.x); 
	//	vec4 alb2 =texture(alb_h_2, UV*uv_scale.y); 
	vec4 alb3 =texture(alb_h_3, UV*uv_scale.z); 
	//	vec4 alb4 =texture(alb_h_4, UV*uv_scale.w); 
	vec4 n1 =texture(norm_r_1, UV*uv_scale.x); 
	//	vec4 n2 =texture(norm_r_2, UV*uv_scale.y); 
	vec4 n3 =texture(norm_r_3, UV*uv_scale.z); 
	//	vec4 n4 =texture(norm_r_4, UV*uv_scale.w); 
	float splat_color = get_splat_color(COLOR);
	//float dp = dot(NORMAL, vec3(0.0,0.0,1.0));
	
	ROUGHNESS= 0.65*(n1.a * splat_color + n3.a * (1.0-splat_color)) ;
	//mat3 tbn = (mat3(TANGENT , -BINORMAL , NORMAL));
//	n1.rgb =  apply_normal_basis(n1.rgb, NORMAL);
//	n3.rgb =  apply_normal_basis(n3.rgb, NORMAL);
	NORMAL_MAP = 0.5*((n1).rgb * splat_color  + (n3).rgb * (1.0-splat_color ));
	ALBEDO = 0.5*(alb1.rgb * splat_color  + alb3.rgb *(1.0-splat_color ));

	/*}*/

}

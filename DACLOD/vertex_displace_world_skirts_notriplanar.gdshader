// NOTE: Shader automatically converted from Godot Engine 4.6.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

#include "assets/compute/global_inc.gdshaderinc"

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

vec4 texture_triplanar(sampler2D tex, vec3 _world_pos, vec3 normal, vec2 _uv_scale) {
    // Blend factors based on the normal, abs to ensure positive values
    vec3 blend = abs(normalize(normal));

    // Normalize blend factors to ensure they sum to 1
    blend /= (blend.x + blend.y + blend.z);

    // Smooth the blend factors to reduce artifacts
    float sharpness = 2.0; // Adjust sharpness as needed
    blend = pow(blend, vec3(sharpness));

    // Normalized again after smoothing
    blend /= dot(blend, vec3(1.0));

    // Texturing for each plane
    vec4 texX = texture(tex, _world_pos.yz / _uv_scale) * blend.x;
    vec4 texY = texture(tex, _world_pos.xz / _uv_scale) * blend.y;
    vec4 texZ = texture(tex, _world_pos.xy / _uv_scale) * blend.z;

    // Final color blend
    return texX + texY + texZ;
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

varying float vy;

void vertex() {
	
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	UV = vec2(world_pos.xz/128.0 );//- floor(world_pos.xz/127.0 )) ;

	NORMAL = compute_normal(texture_height,HEIGHT_SCALE,4096.0, world_pos ).xyz;


	vy = VERTEX.y;

	BINORMAL = normalize(cross(TANGENT, NORMAL));
	TANGENT = normalize((cross(NORMAL, BINORMAL)));
	
	
	


	VERTEX.y +=  HEIGHT_SCALE*texture(texture_height, vec2(world_pos.x/4096.0,world_pos.z/4096.0)).r;
	
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	float h1 =texture(alb_h_1, UV*uv_scale.x).a; 
	//float h2 =texture(alb_h_2, UV*uv_scale.y).a; 
	float h3 =texture(alb_h_3, UV*uv_scale.z).a; 
	//float h3 =texture(alb_h_3, UV*uv_scale.z).a; 
	//float h4 =texture(alb_h_4, UV*uv_scale.w).a; 		
	vec4 splat_map = texture(splat_tex, world_pos.xz/4096.0);
		
	//vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT, -BINORMAL , NORMAL));
	float splat_color = get_splat_color(splat_map);
	float hval = splat_function(splat_color, h1,h3);// + (1.0-splat_color)* h3);



	// this function ,must be the same as the function that generates the collisions
	// the vy check is for the terrain tiles *with* skirts ... not currently used.
	if (vy > -0.5)
		VERTEX =  displace( vec4(VERTEX,1.0), 5.0,  hval, vec4(NORMAL,1.0)).xyz;// - 2.5 * NORMAL;			
	else
	{
		// COMPUTE TEXTURE COORDINATES FOR THIS SKIRTS... THIS HAPPENS
		// BECAUSE THE TEXTURE COORDINATES ARE COMPUTED FROM WORLD COORDINATES
		// BUT THE X OR Z COORDINATE OF THE SKIRT IS THE SAME AS THE TERRAIN VERTEX ABOVE
		// SO I AM ADDING THE VERTICAL DISTANCE TO THE TEXTURE COORDINATE ALONG THE X OR Z AXIS 
		
		if( VERTEX.x < 0.75){
			UV = vec2( (world_pos.x + vy) / 128.0, world_pos.z / 128.0);
		}
		if( VERTEX.x > 128.0-0.25){
			UV = vec2( (world_pos.x+vy) / 128.0, world_pos.z / 128.0);
		}
		if( VERTEX.z < 0.75){
			UV = vec2( world_pos.x / 128.0, (world_pos.z+vy) / 128.0);
		}		
		if( VERTEX.z > 128.0-0.25){
			UV = vec2( world_pos.x / 128.0, (world_pos.z+vy) / 128.0);
		}
	}
	//world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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

	//vec4 alb1 =texture(alb_h_1, UV*uv_scale.x); 
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

	//if( vy > -1.0)
	NORMAL_MAP =0.5*((n1).rgb * splat_color  + (n3).rgb * (1.0-splat_color ));
	
	// attempt to darken the area near the split slightly to hide the skirt	
	// THIS SEEMS TO WORK
	// HAVE NOT NOTICED SPLITS FROM ANY ANGLE WITH THIS ADDED IN
	if ( vy < 0.0) {
		NORMAL_MAP =0.4*((n1).rgb * splat_color  + (n3).rgb * (1.0-splat_color ));
	}
	
	ALBEDO = 0.5*(alb1.rgb * splat_color  + alb3.rgb *(1.0-splat_color ));
	SPECULAR = 0.25;
	/*}*/

}

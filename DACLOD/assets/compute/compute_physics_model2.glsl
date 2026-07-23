#[compute]
#version 450

#include "res://assets/compute/global_inc.gdshaderinc"

layout(local_size_x = 128, local_size_y = 1, local_size_z = 1) in;

// These seem to interfere with the set 0 bindings from the earlier shader if binding = 0,1,2 etc

layout(set = 0, binding = 9) restrict uniform MyData{
	vec4 ich;
	vec4 uv_scale;
} my_data;

layout(set = 0, binding = 11) uniform sampler2D height_tex;
layout(set = 0, binding = 12) uniform sampler2D splat_tex;

layout(set = 0, binding = 13) uniform sampler2D tex1;
layout(set = 0, binding = 14) uniform sampler2D tex3;


layout(set = 0, binding = 10) restrict buffer mesh_verts{
	vec4 data[];
}source_verts;

layout(set = 0, binding = 15) restrict buffer result_mesh_verts{
	vec4 data[];
}dest_verts;

//layout(set = 0, binding = std430) restrict buffer indices{
//	uint data[];
//} tri;

void main() {

	vec2 grid_coord = vec2(my_data.ich.x, my_data.ich.y);
	vec4 uv_scale = my_data.uv_scale;
	float splat_col = my_data.ich.w;
	float HEIGHT_SCALE = my_data.ich.z;

	uint id = gl_GlobalInvocationID.x;
	if (id <= 129*129 ){
	
		vec4 VERTEX = source_verts.data[id];
	

		float world_pos_x = grid_coord.x*128.0 + VERTEX.x - 0.50;
		float world_pos_z = grid_coord.y*128.0 + VERTEX.z - 0.50;

		vec2 height_UV = vec2( world_pos_x / 4096.0, world_pos_z / 4096.0 );


		vec2 bump_UV = vec2( world_pos_x /128.0, world_pos_z /128.0 ); 
	
	
		

		vec4 NORMAL = compute_normal(height_tex, HEIGHT_SCALE, 4096.0, vec3(world_pos_x, 0.0, world_pos_z));

		VERTEX.y = HEIGHT_SCALE * texture( height_tex, height_UV ).r;
	

		float h1 =texture( tex1, bump_UV * uv_scale.x ).a; 
		float h3 =texture( tex3, bump_UV * uv_scale.z ).a; 

		vec4 splat_map = texture(splat_tex, height_UV );
		
		float splat_color = 0.0;
		if (splat_col == 0.0){
		splat_color = splat_map.r;
		} 
		else if (splat_col == 1.0){
		splat_color = splat_map.g;
		}
		else if (splat_col == 2.0){
		splat_color = splat_map.b;
		}
		else {
		splat_color = splat_map.a;
		}

		float hval = splat_function (splat_color, h1 , h3);
		
		VERTEX =  displace(VERTEX, 5.0, hval, NORMAL) ;
		VERTEX.x -= 0.50;
		VERTEX.z -= 0.50;

 		dest_verts.data[id] = VERTEX;	
	}	
	
}

#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;


layout(set = 0, binding = 10) uniform sampler2D height_tex;
layout(set = 0, binding = 5) uniform sampler2D splat_tex;

layout(set = 0, binding = 6) uniform sampler2D tex1;
layout(set = 0, binding = 7) uniform sampler2D tex3;


layout(set = 0, binding = 8, rgba32f) uniform image2D mesh_verts;

layout(set = 0, binding = 9, rgba32f) uniform image2D output_verts;

//layout(set = 0, binding = 6) restrict readonly buffer Params {

	
//}params;







void main() {


	vec2 grid_coord = vec2(12.0f, 12.0f);
	vec4 uv_scale = vec4( 4.0f, 4.0f, 16.0f, 4.0f);
	float splat_col = 2.0f;
	float HEIGHT_SCALE = 500.0f;


	ivec2 UV_IO = ivec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y);
	vec4 vert = imageLoad(mesh_verts, UV_IO );
	vec3 VERTEX = vec3( vert.x, vert.y, vert.z);

	float world_pos_x = grid_coord.x + VERTEX.x;
	float world_pos_z = grid_coord.y + VERTEX.z;

	vec2 height_UV = vec2( world_pos_x / 4096.0, world_pos_z / 4096.0 );

	vec2 height_UV0 = vec2( (world_pos_x - 1.0) / 4096.0, (world_pos_z      ) / 4096.0 );
	vec2 height_UV1 = vec2( (world_pos_x + 1.0) / 4096.0, (world_pos_z      ) / 4096.0 );
	vec2 height_UV2 = vec2( (world_pos_x      ) / 4096.0, (world_pos_z - 1.0) / 4096.0 );
	vec2 height_UV3 = vec2( (world_pos_x      ) / 4096.0, (world_pos_z + 1.0) / 4096.0 );

	vec2 bump_UV = vec2( world_pos_x /127.0, world_pos_z /127.0 ); 
	
	
	float H0 = HEIGHT_SCALE*texture( height_tex, height_UV0 ).r;
	float H1 = HEIGHT_SCALE*texture( height_tex, height_UV1 ).r;
	float H2 = HEIGHT_SCALE*texture( height_tex, height_UV2 ).r;
	float H3 = HEIGHT_SCALE*texture( height_tex, height_UV3 ).r;
	
	vec3 NORMAL = -normalize(vec3(2.0*(H1 - H0), -4.0, 2.0*(H3-H2) ));

	VERTEX.y +=  HEIGHT_SCALE * texture( height_tex, height_UV ).r;

		
		
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

	float hval = (splat_color* h1 + (1.0-splat_color)* h3);
		
	VERTEX +=  5.0 * hval * NORMAL;// - 2.5 * NORMAL;

	vec4 output_vec = vec4( VERTEX.x, VERTEX.y, VERTEX.z, 1.0);
	imageStore(output_verts, UV_IO, output_vec);

	
		
	
}

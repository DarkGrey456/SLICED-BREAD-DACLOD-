#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 1, rgba32f) uniform image2D height_image2;
layout(set = 0, binding = 2, rgba32f) uniform image2D data_output_image2;


shared float sdata_min[64];
shared float sdata_max[64];




void main() {

	ivec2 UV = ivec2( int(gl_GlobalInvocationID.x), int(gl_GlobalInvocationID.y) ); 
	
	ivec2 UV_out = ivec2( int( float(UV.x) / 8), int( float(UV.y) / 8) );
	
	uint local_index = gl_LocalInvocationID.x + gl_LocalInvocationID.y * 8; 
	
	sdata_min[local_index] =  imageLoad(height_image2, UV ).r;
	sdata_max[local_index] =  imageLoad(height_image2, UV ).g;	
	
	memoryBarrierShared();
	barrier();
	
	float min_h = 100000.0;
	float max_h = -100000.0;
	
	for (uint i = 0; i<64; i++){
		
		if ( sdata_min[i] < min_h ){
			min_h = sdata_min[i];
		} 
		if ( sdata_max[i] > max_h ){
			max_h = sdata_max[i];
		}	
	}
	memoryBarrierShared();
	barrier();
	
	vec4 output_data_vec = vec4( min_h, max_h, min_h, max_h);
	
	imageStore(data_output_image2, UV_out, output_data_vec);
}

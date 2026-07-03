#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, r32f) uniform image2D height_image;
layout(set = 0, binding = 1, rgba32f) uniform image2D data_output_image;

shared float sdata[64];

void main() {

	ivec2 UV = ivec2( int(gl_GlobalInvocationID.x), int(gl_GlobalInvocationID.y) ); 
	
	ivec2 UV_out = ivec2( int( float(UV.x) / 8), int( float(UV.y) / 8) );
	
	uint local_index = gl_LocalInvocationID.x + gl_LocalInvocationID.y * 8; 
	
	sdata[local_index] =  500.0 * imageLoad(height_image, UV ).r;
	
	memoryBarrierShared();
	barrier();
	
	float min_h = 100000.0;
	float max_h = -100000.0;
	
	for (uint i = 0; i<64; i++){
		
		if ( sdata[i] > max_h ){
			max_h = sdata[i];
		} 
		if ( sdata[i] < min_h ){
			min_h = sdata[i];
		}	
	}
	memoryBarrierShared();
	barrier();
	


	vec4 output_data_vec = vec4( min_h, max_h, min_h, max_h);
	
	
	imageStore(data_output_image, UV_out, output_data_vec);
}

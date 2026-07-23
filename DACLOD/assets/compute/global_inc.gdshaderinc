

vec4 displace(vec4 vert, float displace_val, float hval, vec4 norm){
	return vert + displace_val * hval * norm;
}


float splat_function( float splat, float h1, float h2){
	return (splat* h1 + (1.0-splat)* h2);
}

vec4 splat_function( float splat, vec4 h1, vec4 h2){
	return (splat* h1 + (1.0-splat)* h2);
}

vec3 splat_function( float splat, vec3 h1, vec3 h2){
	return (splat* h1 + (1.0-splat)* h2);
}

vec4 compute_normal( sampler2D height_tex, float height_scale, float tex_size, vec3 pos ){

		vec2 height_UV0 = vec2( (pos.x - 1.0) / tex_size, (pos.z      ) / tex_size );
		vec2 height_UV1 = vec2( (pos.x + 1.0) / tex_size, (pos.z      ) / tex_size );
		vec2 height_UV2 = vec2( (pos.x      ) / tex_size, (pos.z - 1.0) / tex_size );
		vec2 height_UV3 = vec2( (pos.x      ) / tex_size, (pos.z + 1.0) / tex_size );

		float H0 = height_scale*texture( height_tex, height_UV0 ).r;
		float H1 = height_scale*texture( height_tex, height_UV1 ).r;
		float H2 = height_scale*texture( height_tex, height_UV2 ).r;
		float H3 = height_scale*texture( height_tex, height_UV3 ).r;
		//vec3 v1 = vec3(world_pos.x - 1.0, H0, world_pos.z);
		//vec3 v2 = vec3(world_pos.x + 1.0, H1, world_pos.z);
		//vec3 v3 = vec3(world_pos.x, H2, world_pos.z - 1.0);
		/*vec3 v4 = vec3(world_pos.x, H3, world_pos.z + 1.0);
		vec3 VA = vec3( 2.0, H1 - H0, 0.0 );
		vec3 VB = vec3( 0.0, H3 - H2, 2.0);
		vec3 VX = cross(VA,VB); */
		// i j k 
		// 2 A 0     = i (2 A) - j (4) + k (2 B)
		// 0 B 2
		vec3 n = -normalize(vec3( 2.0*(H1-H0), -4.0, 2.0*(H3-H2) ));

		return vec4( n.x, n.y, n.z, 0.0 );
}

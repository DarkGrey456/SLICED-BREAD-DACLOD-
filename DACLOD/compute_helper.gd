@tool
class_name ComputeHelper
extends Node3D

var compute: EasyCompute = EasyCompute.new()


# Called when the node enters the scene tree for the first time.



func generate_AABB_and_occluders(height_map:Image)->PackedVector4Array:
	compute.load_shader("fill", "res://assets/compute/fill42.glsl")
		
	var image = height_map
	if image.is_compressed():
		image.decompress()	
	image.convert(Image.FORMAT_RF)
	var texture = ImageTexture.create_from_image(image)
	var source_size = 4096
	
	# FIRST PASS, Find min and max height values
	compute.register_texture("height_image", 0, source_size, source_size, image.get_data(), RenderingDevice.DATA_FORMAT_R32_SFLOAT)
	compute.register_texture("data_output_image", 1, 512, 512,[], RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT)
	compute.execute("fill", 512, 512)
	compute.sync()

	var image_data = compute.fetch_texture("data_output_image")

	compute.unload_shader("fill")
	
	
	# SECOND PASS, Find min and max height values
	compute.load_shader("fill_min_max", "res://assets/compute/fill_min_max4.glsl")
	compute.register_texture("height_image2", 1, 512, 512, image_data, RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT)
	compute.register_texture("data_output_image2", 2, 64, 64, [], RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT)
	compute.execute("fill_min_max", 64,64)
	compute.sync()
	
	
	var final_image_data = compute.fetch_texture("data_output_image2")
	var float_data = final_image_data.to_vector4_array()
	
	compute.unload_shader("fill_min_max")
	
	return float_data
	
	#var box_array = []
	#for i in range(64):
		#box_array.append([])
		#
	#for y in range(64):
		#for x in range(64):
			#var indx = x + y * 64
			#
			#var height = float_data[indx].y #-float_data[indx].x
			#var BOX :=MeshInstance3D.new()
			#BOX.mesh = BoxMesh.new()
			#(BOX.mesh as BoxMesh).size.x = 64
			#(BOX.mesh as BoxMesh).size.z = 64
			#(BOX.mesh as BoxMesh).size.y = height 
			#add_child(BOX)
			#BOX.global_position.x = x * 64 + 32
			#BOX.global_position.z = y * 64 + 32
			#BOX.global_position.y =  height / 2.0 #+ float_data[indx].x
			#if float_data[indx].y > max:
				#max = float_data[indx].y
			#if float_data[indx].x < min:
				#min = float_data[indx].x			

	#print(min)
	#print(max)	
	#
	#var output_image = Image.create_from_data(64, 64, false, Image.FORMAT_RGBAF, final_image_data)
	#var texture2 = ImageTexture.create_from_image(output_image)


#=======================================================================================================

#layout(set = 0, binding = 0) uniform sampler2D height_tex;
#layout(set = 0, binding = 1) uniform sampler2D splat_tex;
#
#layout(set = 0, binding = 2) uniform sampler2D tex1;
#layout(set = 0, binding = 3) uniform sampler2D tex3;
#
#
#layout(std140,set = 1, binding = 4) readonly buffer Faces{
#
	#vec3 data[];
#} faces;
#
#
#layout(set = 0, binding = 5, std430) restrict readonly buffer Params {
	#vec2 grid_coord;
	#vec4 uv_scale;
	#uint splat_col;
	#float HEIGHT_SCALE;
	#
#}params;
#
#
#layout(std140,set = 1, binding = 6) writeonly buffer OutputFaces{
#=======================================================================================================
func generate_physics_shape(height_map:Image, 
							splat_map:Image, 
							tex1:Image, 
							tex2:Image, 
							grid_coord:Vector2,
							uv_scale:Vector4,
							splat_col:int,
							HEIGHT_SCALE:float,
							mesh_verts:Image):
								
	compute.load_shader("compute_height", "res://assets/compute/compute_physics_model.glsl")
		
	var image = height_map
	if image.is_compressed():
		image.decompress()	
	image.convert(Image.FORMAT_RF)
	var height_texture = ImageTexture.create_from_image(image)
	var source_size = 4096
	
	var splat_image = splat_map
	if splat_image.is_compressed():
		splat_image.decompress()	
	splat_image.convert(Image.FORMAT_RGBA8)
	
	var tex1_image = tex1
	if tex1_image.is_compressed():
		tex1_image.decompress()	
	tex1_image.convert(Image.FORMAT_RGBA8)
	
	var tex2_image = tex2
	if tex2_image.is_compressed():
		tex2_image.decompress()	
	tex2_image.convert(Image.FORMAT_RGBA8)	


	compute.register_sampler("height_tex", 0, source_size, source_size, image.get_data(), RenderingDevice.DATA_FORMAT_R32_SFLOAT)	
	compute.register_sampler("splat_tex", 5, source_size, source_size, splat_image.get_data(), RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM)	
	compute.register_sampler("tex1", 6, 512, 512, tex1_image.get_data(), RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM)	
	compute.register_sampler("tex3",7, 512, 512, tex2_image.get_data(), RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM)	
		
	if mesh_verts.is_compressed():
		mesh_verts.decompress()
	compute.register_texture("mesh_verts", 8, 128, 128, mesh_verts.get_data(), RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT)
	
	
	


	compute.register_texture("output_verts", 9, 128, 128,[], RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT)
	#var params = PackedFloat32Array([grid_coord.x, grid_coord.y, 
									#uv_scale.x, uv_scale.y, uv_scale.z, uv_scale.w, 
									#float(splat_col), 
									#HEIGHT_SCALE])
	#var params_byte_array = params.to_byte_array()
	#compute.register_storage_buffer("Params", 6, params_byte_array.size(), params_byte_array)
	# FIRST PASS, Find min and max height values

	compute.execute("compute_height", 8, 8)
	compute.sync()
	
	var final_mesh_data = compute.fetch_buffer("output_verts")
	var float_data = final_mesh_data.to_vector3_array()
	print(float_data)
	compute.unload_shader("compute_height")

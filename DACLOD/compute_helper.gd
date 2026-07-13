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
							splat_col:float,
							HEIGHT_SCALE:float,
							mesh_verts:PackedVector4Array)->PackedVector4Array:
								
	compute.load_shader("compute_height", "res://assets/compute/compute_physics_model2.glsl")
		
	var image = height_map
	if image.is_compressed():
		image.decompress()	
	image.convert(Image.FORMAT_RF)
	#var height_texture = ImageTexture.create_from_image(image)
	var source_size = 4096
	
	var splat_image = splat_map
	#if splat_image.is_compressed():
		#splat_image.decompress()	
	splat_image.convert(Image.FORMAT_RGBA8)
	#

	var tex1_image = tex1.duplicate()
	#if tex1_image.is_compressed():
		#tex1_image.decompress()	
	if tex1_image.has_mipmaps():
		tex1_image.clear_mipmaps()		
	tex1_image.convert(Image.FORMAT_RGBA8)
	
	var tex2_image = tex2.duplicate()
	if tex2_image.is_compressed():
		tex2_image.decompress()	
	if tex2_image.has_mipmaps():
		tex2_image.clear_mipmaps()
	tex2_image.convert(Image.FORMAT_RGBA8)	


	compute.register_sampler("height_tex", 11, image.get_width(), image.get_height(), image.get_data(), RenderingDevice.DATA_FORMAT_R32_SFLOAT)	
	compute.register_sampler("splat_tex", 12, splat_image.get_width(), splat_image.get_height(), splat_image.get_data(), RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM)	
	compute.register_sampler("tex1", 13, tex1_image.get_width(), tex1_image.get_height(), tex1_image.get_data(), RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM)	
	compute.register_sampler("tex3", 14, tex2_image.get_width(), tex2_image.get_height(), tex2_image.get_data(), RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM)	
		
	#if mesh_verts.is_compressed():
		#mesh_verts.decompress()
	#compute.register_texture("mesh_verts", 8, 128, 128, mesh_verts.get_data(), RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT)
	#
	
	var mesh_byte_array:PackedByteArray = mesh_verts.to_byte_array()
	compute.register_storage_buffer("source_verts", 10, mesh_byte_array.size(), mesh_byte_array)
	
	#var output_byte_array:PackedByteArray
	#compute.register_storage_buffer("res_verts",12, mesh_byte_array.size(), [])
	#compute.register_texture("output_verts", 12, 128, 128,[], RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT)
	#var params = PackedFloat32Array([grid_coord.x, grid_coord.y, 
									#uv_scale.x, uv_scale.y, uv_scale.z, uv_scale.w, 
									#float(splat_col), 
									#HEIGHT_SCALE])
	#var params_byte_array = params.to_byte_array()
	#compute.register_storage_buffer("Params", 6, params_byte_array.size(), params_byte_array)
	# FIRST PASS, Find min and max height values
	var my_data :PackedFloat32Array = [15.0, 
										16.0, 
										HEIGHT_SCALE,
										splat_col,
										uv_scale.x,
										uv_scale.y,
										uv_scale.z,
										uv_scale.w]
	var my_data_bytes = my_data.to_byte_array()
	compute.register_uniform_buffer("my_data",9,my_data_bytes.size(),my_data_bytes )	
	
	compute.execute("compute_height", mesh_verts.size()/128, 1, 1 )
	compute.sync()
	
	var final_mesh_data = compute.fetch_buffer("source_verts")
	var float_data = final_mesh_data.to_vector4_array()
	return float_data
	#print(float_data)
	#compute.unload_shader("compute_height")

func generate_physics_shape_per_frame(height_map:Image, 
							splat_map:Image, 
							tex1:Image, 
							tex2:Image, 
							grid_coord:Vector2,
							uv_scale:Vector4,
							splat_col:float,
							HEIGHT_SCALE:float,
							mesh_verts:PackedVector4Array)->PackedVector4Array:
	
	var my_data :PackedFloat32Array = [grid_coord.x, 
										grid_coord.y, 
										HEIGHT_SCALE,
										splat_col,
										uv_scale.x,
										uv_scale.y,
										uv_scale.z,
										uv_scale.w]
	var my_data_bytes = my_data.to_byte_array()
	compute.update_buffer("my_data", my_data_bytes )	
		
	compute.execute("compute_height", mesh_verts.size()/128, 1, 1 )
	compute.sync()
	
	var final_mesh_data = compute.fetch_buffer("source_verts")
	var float_data = final_mesh_data.to_vector4_array()
	return float_data

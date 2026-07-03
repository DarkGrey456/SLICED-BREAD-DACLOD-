@tool
class_name ComputeHelper
extends Node3D

var compute: EasyCompute = EasyCompute.new()


# Called when the node enters the scene tree for the first time.



func texture_fill3()->PackedVector4Array:
	compute.load_shader("fill", "res://assets/compute/fill42.glsl")
	
	var tex :CompressedTexture2D= load("res://assets/Heightmaps/ISLAND_4k_2/height2.exr")
	var image = tex.get_image()
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

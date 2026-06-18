
@tool
extends Node3D


@onready var tiles_256: Node3D = $tiles_257


#@onready var collision_shape_3d: CollisionShape3D = $"../StaticBody3D/CollisionShape3D"

var resolution:int = 128
var occluders = []
var min_h = 100000
var max_h = -2000	

func create_collision_shapes()->void:
	if not Engine.is_editor_hint() and first_time:
		first_time = false
		load_image()
		var grid_size = 4096 / resolution
		for i in range(grid_size):
			for j in range(grid_size):
				var rect:Rect2
				rect.position = Vector2(float(i)*128.0,float(j)*128.0)
				rect.size = Vector2(resolution, resolution)
				grid[i][j].storage[0].aabb = thread_generate_mesh(rect)	

@export_tool_button("make collider")
var make_collider = create_collision_shapes

var grid_size = 32
var cell_size = 128
var xmax = 4096

var grid = []



enum CAM_PLANE{ NEAR_PLANE, FAR_PLANE, LEFT_PLANE, TOP_PLANE, RIGHT_PLANE, BOTTOM_PLANE}
var cam_planes

var x: float = 0
var z: float = 0



class Elem:
	var id: int
	var basis: Basis
	var position: Vector3
	#var mesh:StringName
	var aabb:AABB
	var mesh:MeshInstance3D

class grid_elem:
	var storage = []
	
	



var grid_pattern = [[Vector2i(-1,-1),Vector2i(-1,0),Vector2i(-1,1)],\
					[Vector2i(0,-1),Vector2i(0,0),Vector2i(0,1)],\
					[Vector2i(1,-1),Vector2i(1,0),Vector2i(1,1)]]
	
var point_positions = [ Vector2(1.2,1.5), Vector2(54.4, 1.5), Vector2(12.2,16.8),Vector2(36.0, 36.0),\
						Vector2(1.2,9.5), Vector2(53.4, 9.5), Vector2(12.2,24.8),Vector2(36.0, 42.0),\
						Vector2(1.2,17.5), Vector2(53.4, 17.5), Vector2(12.2,32.8),Vector2(36.0, 50.0),\
						Vector2(1.2,25.5), Vector2(53.4, 25.5), Vector2(12.2,40.8),Vector2(36.0, 58.0)]
var cuurent_point : int = 0

func setup_grid(N:int):
	for i in range(N):
		grid.append([])
		for j in range(N):
			grid[i].append(grid_elem.new())
			grid[i][j].storage.append(Elem.new())
	cell_size = xmax / N
	
	get_cam_planes()
	
func get_cam_planes():
# Get the current active 3D camera
	var camera = get_viewport().get_camera_3d()

	if camera:
		# Retrieve the frustum planes
		var cam_planes = camera.get_frustum()

		# Access individual planes
		var near_plane = cam_planes[0]
		var far_plane = cam_planes[1]
		var left_plane = cam_planes[2]
		var top_plane = cam_planes[3]
		var right_plane = cam_planes[4]
		var bottom_plane = cam_planes[5]

		# Print the planes for debugging
		print("Near Plane: ", near_plane)
		print("Far Plane: ", far_plane)
		print("Left Plane: ", left_plane)
		print("Top Plane: ", top_plane)
		print("Right Plane: ", right_plane)
		print("Bottom Plane: ", bottom_plane)
		
		print("Near Plane: ", cam_planes[CAM_PLANE.NEAR_PLANE])
		print("Far Plane: ", cam_planes[CAM_PLANE.FAR_PLANE])
		print("Left Plane: ", cam_planes[CAM_PLANE.LEFT_PLANE])
		print("Top Plane: ", cam_planes[CAM_PLANE.TOP_PLANE])
		print("Right Plane: ", cam_planes[CAM_PLANE.RIGHT_PLANE])
		print("Bottom Plane: ", cam_planes[CAM_PLANE.BOTTOM_PLANE])		
	else:
		print("No active camera found!")
		
func world_coords_to_grid_coords(px:float,py:float):
	return Vector2i( floor((float(px)) / cell_size),floor((float(py)) / cell_size))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_grid(grid_size)
	if not Engine.is_editor_hint():
		create_collision_shapes()
	for i in grid_size:
		for j in grid_size:
			var dup = tiles_256.duplicate()
			add_child(dup)
			dup.global_position = Vector3(float(i)*128.0, 0.0,float(j)*128.0)
			for ch in dup.get_children():
				((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial).set_shader_parameter("node_pos",Vector2(float(i)*128.0,float(j)*128.0 ))
				(ch as MeshInstance3D).custom_aabb = grid[i][j].storage[0].aabb
				(ch as MeshInstance3D).custom_aabb.position.x = 0.0
				(ch as MeshInstance3D).custom_aabb.position.z = 0.0			 
				#print("Custom: " + var_to_str((ch as MeshInstance3D).custom_aabb))
				#print("Actual: " + var_to_str((ch as MeshInstance3D).get_aabb()))





		
		


func _process(delta: float) -> void:
	pass

				






var hmap:Image 



func load_image():
	hmap = LoadLargeHeightMap("res://assets/Heightmaps/ISLAND_4k_2/height2.exr")
	#(collision_shape_3d.shape as HeightMapShape3D).map_data = hmap.get_data().to_float32_array()
	

func LoadLargeHeightMap(filename:String)->Image:
	var height:Texture2D = load(filename)

	return height.get_image()
	
func get_altitude(pos:Vector3)->float:
	
	if hmap:
		if pos.x < 4096 and pos.z < 4096:
			return hmap.get_pixel(pos.x,pos.z).r* 500.0
		
		return hmap.get_pixel(0,0).r 
	else:
		print("error no heightmap")
		return 0.0
			
	




func generate_mesh_data(rect: Rect2) -> Array:
	var grid_size = resolution + 1
	var step_size = rect.size.x / resolution
	
	# Step 1: Generate Base Height Data
	var height_data = PackedFloat32Array()
	height_data.resize(grid_size * grid_size)
	
	var rect2 = rect
	rect2.size.x +=1
	rect2.size.y +=1
	
	
	#var h_region = hmap.get_region(rect2)
	#var texture:Texture2D = ImageTexture.create_from_image(h_region)
	min_h = 100000	
	max_h = -100000	
	#texture.
	for z in grid_size:
		for x in grid_size:
			var pos_x = rect.position.x + (x * step_size)
			var pos_z = rect.position.y + (z * step_size)
			var h:float = get_altitude(Vector3(pos_x, 0, pos_z))
			if h < min_h:
				min_h = h
			if h > max_h:
				max_h = h
			height_data[x + z * grid_size] = h
	
	# Step 3: Build the Mesh Arrays
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	vertices.resize(grid_size * grid_size)
	uvs.resize(grid_size * grid_size)
	
	for z in grid_size:
		for x in grid_size:
			var i = x + z * grid_size
			var pos_x =  (x * step_size)
			var pos_z =  (z * step_size)
			
			vertices[i] = Vector3(pos_x, height_data[i], pos_z)
			uvs[i] = Vector2( (rect.position.x+float(x)) / (4096.0), (rect.position.y+float(z)) / (4096.0))

	# Indices logic
	for z in resolution:
		for x in resolution:
			var i = x + z * grid_size
			indices.append(i)
			indices.append(i + 1)
			indices.append(i + grid_size)
			indices.append(i + 1)
			indices.append(i + grid_size + 1)
			indices.append(i + grid_size)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	return arrays
	
func thread_generate_mesh(node: Rect2)->AABB:
	# 1. Generate the raw data
	var mesh_data = generate_mesh_data(node)
	
	# 2. DO THE HEAVY LIFTING HERE (Off the main thread)
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	#
	var st = SurfaceTool.new()
	st.create_from(array_mesh, 0)
	st.generate_normals()
	var final_mesh = st.commit() # This is now ready for the GPU
	#

	
	# Pass the completed mesh to the main thread
	#call_deferred("finalize_node", node, final_mesh, min_h)	
	return finalize_node(node, final_mesh, min_h)

func finalize_node(node: Rect2, final_mesh: Mesh,h:float) ->AABB:
	#pending_nodes = max(0, pending_nodes - 1)
	
	# Create the instance - this is now very light
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = final_mesh
	#mesh_instance.material_override = load("uid://dlywemjv2a6fg")
	#(mesh_instance.material_override as ShaderMaterial).set_shader_parameter("global_map",albedo_tex)
	#(mesh_instance.material_override as ShaderMaterial).set_shader_parameter("splat",splat1)
	#(mesh_instance.material_override as ShaderMaterial).set_shader_parameter("splat2",splat2)
	#
	#mesh_instance.set_meta("node", node)
	


	
	var occ = OccluderInstance3D.new()
	var box_occ = BoxOccluder3D.new()
	box_occ.size = Vector3(resolution, h, resolution)
	occ.occluder = box_occ
	
	var aabb_pos:Vector3 = Vector3(node.position.x,min_h,node.position.y)
	var aabb_size:Vector3 = Vector3(128.0,max_h-min_h,128.0)
	var aabb:AABB = AABB(aabb_pos,aabb_size)
	
	
	var box = MeshInstance3D.new()
	box.mesh = BoxMesh.new()
	(box.mesh as BoxMesh).size =  Vector3(resolution, h, resolution)
#
	
	#add the mesh to the scene
	add_child(mesh_instance)
	##set the position
	mesh_instance.global_position = Vector3(node.position.x,0.0,node.position.y)
	## create the collision shape
	mesh_instance.create_trimesh_collision()	
	mesh_instance.visible = false
	## get the static body
	#var static_body = mesh_instance.get_child(0) 
	#if static_body == null:
		#print("cant find collision model")
	#### reparent this to the main scene
	#static_body.reparent(self,true)	
	#static_body.global_position  = Vector3(node.position.x,0.0,node.position.y)
	#static_body.set_collision_layer_value(1,true)
	#static_body.set_collision_mask_value(1,true)
	### queue free the mesh
	#mesh_instance.queue_free()
	
	#add_child(occ)
	#occ.global_position = Vector3(node.position.x+resolution/2.0, h/2.0, node.position.y+resolution/2.0)	
	#add_child(box)
	#box.global_position = Vector3(node.position.x+resolution/2.0, h/2.0, node.position.y+resolution/2.0)	
	
#	

	return aabb


var first_time:bool = true	
#func _process(delta:float) -> void:


			

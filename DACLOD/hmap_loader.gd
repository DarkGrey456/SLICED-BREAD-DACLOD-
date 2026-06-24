
@tool
extends Node3D


@onready var tiles_256: Node3D = $tiles_256


#@onready var collision_shape_3d: CollisionShape3D = $"../StaticBody3D/CollisionShape3D"
@export var height_map_texture:Texture2D
var hmap:Image 

var nmap : Image
var splat_map:Image
var gpuNormals :Texture2D #=  ImageTexture.new()
@export var gpuSplat :Texture2D #= ImageTexture.new()

var alb1:Image
var alb2:Image
var alb3:Image
var alb4:Image

var norm1:Image
var norm2:Image
var norm3:Image
var norm4:Image

@export var alb_h_1:Texture2D
@export var alb_h_2:Texture2D
@export var alb_h_3:Texture2D
@export var alb_h_4:Texture2D

@export var norm_rough_1:Texture2D
@export var norm_rough_2:Texture2D
@export var norm_rough_3:Texture2D
@export var norm_rough_4:Texture2D

@export var UV_SCALE:Vector4 = Vector4(18.0,18.0, 18.0,2.0)

var resolution:int = 128
var occluders = []
var min_h = 100000
var max_h = -2000	

var scale_xz = 1.0
var HEIGHT_SCALE:float = 500.0

#var height_data = PackedFloat32Array()

@export_tool_button("DONT CLICK THIS BUTTON")
var make_collider = create_collision



var x: float = 0
var z: float = 0





#=======================================================================================
# Grid related ... data helper mostly, can also be utilized for data loading
#=======================================================================================

# this variable name was redefined previously
var grid_size = 32
var cell_size = 128
var xmax = 4096

var grid = []

class Elem:
	var id: int
	var basis: Basis
	var position: Vector3
	#var mesh:StringName
	var aabb:AABB
	var mesh:MeshInstance3D
	var node:Node3D
	var collider_active = false

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

func setup_grid(N:int)->void:
	for i in range(N):
		grid.append([])
		for j in range(N):
			grid[i].append(grid_elem.new())
			grid[i][j].storage.append(Elem.new())
	cell_size = xmax / N
	

func world_coords_to_grid_coords(px:float,py:float)->Vector2i:
	return Vector2i( floor((float(px)) / cell_size),floor((float(py)) / cell_size))

# grid utilities ...
func kill_grid_cell(i:int, j:int) ->void:
	for k in grid[i][j].storage:
		grid[i][j].storage.erase(k)

func activate_grid_cell(ii:int, jj:int)->void:
	for k in grid[ii][jj].storage.size():
		var scene = load( grid[ii][jj].storage[k].mesh)
		var p = scene.instantiate()
		#p.global_position = grid[i][j].storage[k].position
		p.transform.basis = grid[ii][jj].storage[k].basis
		p.transform.origin = grid[ii][jj].storage[k].position
		print(p.transform)

		add_child(p)
			
#world_coords_to_grid_coords(player.x, player.z)
func flatten_grid_pattern_at_point(p:Vector2i)->void:
	for i in range(0,3):
		for j in range(0,3):

			var px = grid_pattern[i][j].x +p.x
			var py = grid_pattern[i][j].y +p.y
			if px >= 0 and px < grid_size and py >= 0 and py < grid_size :
					#activate_grid_cell(px,py)
				if grid[px][py].storage[0].collider_active == false:
					grid[px][py].storage[0].collider_active = true
					WorkerThreadPool.add_task(func():thread_create_colliders(px,py,data_mesh_grid))


				
#=======================================================================================
# Colliders
#=======================================================================================


	# Reads all vertices and indices from every surface of a Mesh
func get_mesh_vertices_and_indices(mesh: Mesh) -> Dictionary:
	var result := {
		"vertices": [],
		"indices": []
	}

	if mesh == null:
		push_error("Mesh is null.")
		return result

	var mdt := MeshDataTool.new()

	# Loop through all surfaces because a Mesh can have more than one
	for surface in mesh.get_surface_count():
		var err := mdt.create_from_surface(mesh, surface)
		if err != OK:
			print("Failed to read surface %d" % surface)
			continue

		# Extract vertices
		var vtx_count := mdt.get_vertex_count()
		for i in vtx_count:
			var vert := mdt.get_vertex(i)
			result["vertices"].append(vert)

		# Extract indices (faces are always triangles)
		var face_count := mdt.get_face_count()
		for f in face_count:
			var i1 := mdt.get_face_vertex(f, 0)
			var i2 := mdt.get_face_vertex(f, 1)
			var i3 := mdt.get_face_vertex(f, 2)

			result["indices"].append(i1)
			result["indices"].append(i2)
			result["indices"].append(i3)

		mdt.clear()

	return result


## Example usage
#func _ready():
	#var mesh_instance := $MeshInstance3D
	#if mesh_instance and mesh_instance.mesh:
		#var data := get_mesh_vertices_and_indices(mesh_instance.mesh)
		#print("Vertices count: ", data["vertices"].size())
		#print("Indices count: ", data["indices"].size())



@onready var plane__128: MeshInstance3D = $tiles_256/Plane__128

@export var player:CharacterBody3D

var data_mesh_grid:Dictionary
func create_collision()->void:
	if not Engine.is_editor_hint() and first_time:
		first_time = false
		# first call a function adapted from SimpleTerrain ...
		# this could do all the work, including AABB's and occluders...
		#create_collision_shape()
		
		# but we scan the heightmap twice at the moment
		data_mesh_grid = get_mesh_vertices_and_indices(plane__128.mesh)
		
		var grid_size = xmax / resolution
		for i in range(grid_size):
			for j in range(grid_size):
				WorkerThreadPool.add_task(func():thread_create_occluders(i,j,data_mesh_grid))
				
func thread_create_colliders(i:int, j:int, data:Dictionary):
	var rect:Rect2
	rect.position = Vector2(float(i)*128.0,float(j)*128.0)
	rect.size = Vector2(resolution, resolution)	
	thread_generate_mesh(rect, data, false)		
				
func thread_create_occluders(i:int, j:int, data:Dictionary):
	var rect:Rect2
	rect.position = Vector2(float(i)*128.0,float(j)*128.0)
	rect.size = Vector2(resolution, resolution)	
	thread_generate_mesh(rect, data, true)					
				
# from SimpleTerrain				
func create_collision_shape():
	var static_body : StaticBody3D = get_node_or_null("StaticBody3D")
	if static_body == null:
		static_body = StaticBody3D.new()
		static_body.name = "StaticBody3D"
		add_child(static_body)
		if Engine.is_editor_hint():
			static_body.owner = get_tree().edited_scene_root
	var collision_shape : CollisionShape3D = static_body.get_node_or_null("CollisionShape3D")
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		static_body.add_child(collision_shape)
		if Engine.is_editor_hint():
			collision_shape.owner = get_tree().edited_scene_root
	
	collision_shape.position.x =  xmax /2
	collision_shape.position.z =  xmax /2
	#var xmax = _get_num_verts_along_edge_total(collision_shape_resolution)
	#var scale_xz = (terrain_xz_scale / (_get_num_verts_along_chunk_edge(collision_shape_resolution) - 1))
	collision_shape.scale = Vector3(scale_xz, scale_xz, scale_xz)
	
	# This was causing lag on level spawn but it got fixed randomly at some point? Maybe 4.2.1 bump?
	collision_shape.shape = make_heightmap_shape(get_collision_shape_data(Vector2i(xmax,xmax), scale_xz), Vector2i(xmax,xmax))

# also from SimpleTerrain
func make_heightmap_shape(data : PackedFloat32Array, data_width_depth : Vector2i) -> HeightMapShape3D:
	var shape := HeightMapShape3D.new()
	shape.map_width = data_width_depth.x
	shape.map_depth = data_width_depth.y
	shape.map_data = data
	return shape
	
# make convex collision shape
func make_convex_shape(data : PackedVector3Array, data_width_depth : Vector2i) -> ConcavePolygonShape3D:
	var shape :=  ConcavePolygonShape3D.new()#
	#   HeightMapShape3D.new()
	shape.set_faces(data)

	return shape	

# adapted from simple terrain
func get_collision_shape_data(num_verts_along_edge_total : Vector2i, height_scale_fix : float) -> PackedFloat32Array:
	var map_data := PackedFloat32Array()
	map_data.resize(xmax * xmax)
	
	# Since we must scale the collision shape uniformly, we modify the height of each point, 
	# normalizing it to the terrain_height_scale value
	var scale_y_to_normalize = HEIGHT_SCALE / height_scale_fix
	var heightmap_image = hmap

	var m = -1.0
	for i in map_data.size():
		# Is this right or should be num_verts_along_edge_total + 1
		var x = i % xmax
		var z = floor(i / xmax)

		map_data[i] = heightmap_image.get_pixel(x, z).r * scale_y_to_normalize
		var normal:Color = nmap.get_pixel(x,z)
		var splat:Color = splat_map.get_pixel(x,z)
		
		var m_uv =Vector2( (x / 128.0) - float(int(x / 128)),
						 (z / 128.0) - float(int(z / 128)))
		var h1 = alb1.get_pixelv( m_uv*UV_SCALE.x ).a
		var h2 = alb2.get_pixelv( m_uv*UV_SCALE.y ).a
		var h3 = alb3.get_pixelv( m_uv*UV_SCALE.z ).a
		var h4 = alb4.get_pixelv( m_uv*UV_SCALE.w ).a	
		
		var hval:float = (splat.r* h1 + splat.g * h4 + splat.b * h2 + 0.25*(1.0-splat.g)* h3);
		map_data[i] += 2.5*hval
		#update the grid
		
		#var _I = x / cell_size
		#var _J = z / cell_size
		#if grid[ _I][_J].storage[0].aabb.position.y > map_data[i]:
			#grid[ _I][_J].storage[0].aabb.position.y = map_data[i]
		#if grid[ _I][_J].storage[0].aabb.end.y < map_data[i]:
			#grid[ _I][_J].storage[0].aabb.end.y = map_data[i]
			
		# Create holes for parts of splatmap that are transparent
		#if not _collision_shape_has_vert_at(x, z, splatmap_image):
			#map_data[i] = NAN
	return map_data

func get_collision_shape_trimesh_data(num_verts_along_edge_total : Vector2i, height_scale_fix : float) -> PackedVector3Array:
	var map_data := PackedVector3Array()
	map_data.resize(xmax * xmax)
	
	# Since we must scale the collision shape uniformly, we modify the height of each point, 
	# normalizing it to the terrain_height_scale value
	var scale_y_to_normalize = HEIGHT_SCALE / height_scale_fix
	var heightmap_image = hmap

	var m = -1.0
	for i in map_data.size():
		# Is this right or should be num_verts_along_edge_total + 1
		var x = i % xmax
		var z = floor(i / xmax)

		map_data[i] = Vector3(float(x), heightmap_image.get_pixel(x, z).r * scale_y_to_normalize, float(z))
		var normal_pix:Color = nmap.get_pixel(x,z)
		var normal = Vector3(normal_pix.r, normal_pix.g, normal_pix.b )
		var splat:Color = splat_map.get_pixel(x,z)
		
		var m_uv =Vector2( (x / 128.0) - float(int(x / 128)),
						 (z / 128.0) - float(int(z / 128)))
		var h1 = alb1.get_pixelv( m_uv*UV_SCALE.x ).a
		var h2 = alb2.get_pixelv( m_uv*UV_SCALE.y ).a
		var h3 = alb3.get_pixelv( m_uv*UV_SCALE.z ).a
		var h4 = alb4.get_pixelv( m_uv*UV_SCALE.w ).a	
		
		var hval:float = (splat.g* h1 +(1.0 -splat.g) * h3)# + splat.b * h2 + 0.25*(1.0-splat.g)* h3);
		map_data[i] += 5.0 * normal * hval - 2.5 * normal

	
	return map_data
	
#=======================================================================================
# heightmap accessor functions
#=======================================================================================
func load_image()->void:
	hmap = LoadLargeHeightMap("res://assets/Heightmaps/ISLAND_4k_2/height2.exr")
	#self.HEIGHT_SCALE/xmax
	create_normal_map(hmap, self.HEIGHT_SCALE, "res://assets/Heightmaps/ISLAND_4k_2/normal_map.png")
	

	
	#gpuSplat = load("res://assets/Heightmaps/ISLAND_4k_2/splat.png")
	
	splat_map = gpuSplat.get_image()
	if splat_map.is_compressed():
		splat_map.decompress()
	
	load_shader_images()


func load_shader_images()->void:
	#alb_h_1 = load("res://assets/textures/slot1_albedo_bump.png")
	#alb_h_2 = load("res://assets/textures/prototype_slot2_albedo_bump.png")
	#alb_h_3 = load("res://assets/textures/slot0_albedo_bump.png")
	#alb_h_4 = load("res://assets/textures/prototype_slot3_albedo_bump.png")
#
#
	#norm_rough_1 = load("res://assets/textures/slot1_normal_roughness.png")
	#norm_rough_2 = load("res://assets/textures/prototype_slot2_normal_roughness.png")
	#norm_rough_3 = load("res://assets/textures/slot0_normal_roughness.png")
	#norm_rough_4 = load("res://assets/textures/prototype_slot3_normal_roughness.png")
	
	alb1 = alb_h_1.get_image()
	alb2 = alb_h_2.get_image()
	alb3 = alb_h_3.get_image()
	alb4 = alb_h_4.get_image()
	
	if alb1.is_compressed():
		alb1.decompress()
	if alb2.is_compressed():
		alb2.decompress()
	if alb3.is_compressed():
		alb3.decompress()
	if alb4.is_compressed():
		alb4.decompress()						
	
	norm1 = norm_rough_1.get_image()
	norm2 = norm_rough_2.get_image()
	norm3 = norm_rough_3.get_image()
	norm4 = norm_rough_4.get_image()
	


	

func LoadLargeHeightMap(filename:String)->Image:
	#var height:Texture2D = load(filename)

	return height_map_texture.get_image()
	
func LoadTexture(filename:String)->Texture2D:
	var height:Texture2D = load(filename)

	return height	
	
func get_altitude(pos:Vector3)->float:
	
	if hmap:
		if pos.x < xmax and pos.z < xmax:
			return hmap.get_pixel(pos.x,pos.z).r * HEIGHT_SCALE
		
		return hmap.get_pixel(0,0).r 
	else:
		print("error no heightmap")
		return 0.0
			
# bump scale is HEIGHT_SCALE
func create_normal_map(height_map:Image, bump_scale:float, path:String)->void:
	
	gpuNormals = load(path) 
	
	if (gpuNormals == null) :#or gpuNormals.is_empty():
		nmap = height_map.duplicate(true)
		var path_to_hmap = height_map_texture.resource_path
		
		var last_slash = path_to_hmap.rfind("/")
		var substr = path_to_hmap.substr(0,last_slash)
		
		nmap.bump_map_to_normal_map(bump_scale)
		gpuNormals = ImageTexture.new()
		gpuNormals.create_from_image(nmap)
	
		# Save with error checking
		var save_err := nmap.save_png(substr + "/normal_map.png")
		if save_err != OK:
			push_error("Failed to save normal map: %s" % path)
			return

		print("Normal map generated:", path)	
		
		
	
		# cancel the run and reload, the normal map should work now ... just
		# a weird problem in that i can't get the nmap 

		if nmap.is_compressed():
			nmap.decompress()
	else:
		nmap = gpuNormals.get_image()
	# Save with error checking
	#var save_err := img.save_png(normal_path)
	#if save_err != OK:
		#push_error("Failed to save normal map: %s" % normal_path)
		#return
#
	#print("Normal map generated:", normal_path)
	
#=======================================================================================
# get AABB and Occluder
#=======================================================================================
func generate_mesh_data(rect: Rect2,data:Dictionary) -> Dictionary:
	var subdiv_size = resolution + 1
	var step_size = rect.size.x / resolution
	
	# Step 1: Generate Base Height Data
	#height_data.resize(subdiv_size * subdiv_size)
	
	var rect2 = rect
	rect2.size.x +=1
	rect2.size.y +=1
	

	var h_min = 100000	
	var h_max = -100000	

				
	var collision_data := PackedVector3Array()
	collision_data.resize(data["indices"].size())
	for i in data["indices"].size()-3:	
		var i1 = data["indices"][i]
		var i2 = data["indices"][i+1]
		var i3 = data["indices"][i+2]
		
		var v1 = Vector3(data["vertices"][i1])
		var v2 = Vector3(data["vertices"][i2])
		var v3 = Vector3(data["vertices"][i3])
		
		
		var pos_x1 = rect.position.x + v1.x
		var pos_z1 = rect.position.y + v1.z
		v1.y = get_altitude(Vector3(pos_x1, 0, pos_z1))

		if v1.y < h_min:
			h_min = v1.y
		if v1.y > h_max:
			h_max = v1.y
						
		var pos_x2 = rect.position.x + v2.x
		var pos_z2 = rect.position.y + v2.z
		v2.y = get_altitude(Vector3(pos_x2, 0, pos_z2))

		
		if v2.y  < h_min:
			h_min = v2.y 
		if v2.y  > h_max:
			h_max = v2.y 		
		
		var pos_x3 = rect.position.x + v3.x
		var pos_z3 = rect.position.y + v3.z
		var h3:float = get_altitude(Vector3(pos_x3, 0, pos_z3))

		v3.y = h3 
				
		if v3.y < h_min:
			h_min = v3.y
		if v3.y > h_max:
			h_max = v3.y	
					
		collision_data.append( v1)
		collision_data.append( v2)
		collision_data.append( v3 )
		
		i+=3
		
		
		
	for i in collision_data.size():
		var v = collision_data[i]
		var dict1 = get_map_values(v.x, v.z)
		v +=  5.0 * dict1["normal"] * dict1["height"] - 2.5 * dict1["normal"] 		
		collision_data[i] = v	
		
	var static_body : StaticBody3D = StaticBody3D.new()
	static_body.name = "StaticBody3D_"+var_to_str(rect.position.x/cell_size)+"_"+var_to_str(rect.position.y/cell_size)

	call_deferred("add_child",static_body)
	static_body.connect("tree_entered", Callable(self, "_on_tree_entered").bind(static_body,Vector3(rect.position.x, 0.0, rect.position.y)))
	
	if Engine.is_editor_hint():
		static_body.owner = get_tree().edited_scene_root
		
	var collision_shape : CollisionShape3D  = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	static_body.add_child(collision_shape)
	#var xmax = _get_num_verts_along_edge_total(collision_shape_resolution)
	#var scale_xz = (terrain_xz_scale / (_get_num_verts_along_chunk_edge(collision_shape_resolution) - 1))
	collision_shape.scale = Vector3(scale_xz, scale_xz, scale_xz)
	


	# This was causing lag on level spawn but it got fixed randomly at some point? Maybe 4.2.1 bump?
	collision_shape.shape = ConcavePolygonShape3D.new()
	collision_shape.shape.set_faces(collision_data)
		
	if Engine.is_editor_hint():
		collision_shape.owner = get_tree().edited_scene_root
	



	return {
				"h_min":h_min,
				"h_max":h_max
			}
	
func get_map_values(x:float, z:float):
	var normal_pix:Color = nmap.get_pixel(int(x),int(z))
	var normal = Vector3(normal_pix.r, normal_pix.g, normal_pix.b )
	var splat:Color = splat_map.get_pixel( int(x),int(z) )
		
	var m_uv =Vector2( (x / 128.0) - float(int(x / 128.0)),
						 (z / 128.0) - float(int(z / 128.0)))
	var disp1 = alb1.get_pixelv( m_uv*UV_SCALE.x ).a
	var disp2 = alb2.get_pixelv( m_uv*UV_SCALE.y ).a
	var disp3 = alb3.get_pixelv( m_uv*UV_SCALE.z ).a
	var disp4 = alb4.get_pixelv( m_uv*UV_SCALE.w ).a	
		
	var hval:float = (splat.g* disp1 +(1.0 -splat.g) * disp3)			
	
	return {
		"normal":normal,
		"height":hval
	}
	
#=======================================================================================
# get AABB and Occluder
#=======================================================================================
func generate_occluders(rect: Rect2,data:Dictionary) -> Dictionary:
	var subdiv_size = resolution + 1
	var step_size = rect.size.x / resolution
	
	# Step 1: Generate Base Height Data
	#height_data.resize(subdiv_size * subdiv_size)
	
	var rect2 = rect
	rect2.size.x +=1
	rect2.size.y +=1
	

	var h_min = 100000	
	var h_max = -100000	
	
	var h_data = []
	for i in resolution:
		h_data.append([])
		
	
		
	#texture.
	for z in resolution:
		for x in resolution:
			var pos_x = rect.position.x + (x * step_size)
			var pos_z = rect.position.y + (z * step_size)
			var h:float = get_altitude(Vector3(pos_x, 0, pos_z))
			if h < h_min:
				h_min = h
			if h > h_max:
				h_max = h
			#height_data[x + z * subdiv_size] = h
		#

	return {
				"h_min":h_min,
				"h_max":h_max
			}	
	
# no longer threaded
func thread_generate_mesh(node: Rect2, data:Dictionary, gen_occluders:bool)->void:
	# 1. Generate the raw data
	
	var mesh_data
	if gen_occluders:
		
		finalize_node( node, generate_occluders(node,data) )
	else:	
		mesh_data = generate_mesh_data(node,data)

	# Pass the completed mesh to the main thread
	#call_deferred("finalize_node", node, mesh_data)	
#	return finalize_node( node, mesh_data )

# no real mesh here, just an AABB and an occluder
func finalize_node(rect: Rect2, h_dict: Dictionary) ->void:
	#pending_nodes = max(0, pending_nodes - 1)

	var occ = OccluderInstance3D.new()
	var box_occ = BoxOccluder3D.new()
	box_occ.size = Vector3(cell_size, h_dict["h_min"], cell_size)
	occ.occluder = box_occ
	
	var aabb_pos:Vector3 = Vector3(0.0,h_dict["h_min"],0.0)
	var aabb_size:Vector3 = Vector3(cell_size,h_dict["h_max"]-h_dict["h_min"],cell_size)
	var aabb:AABB = AABB(aabb_pos, aabb_size)
	
	
	var box = MeshInstance3D.new()
	box.mesh = BoxMesh.new()
	(box.mesh as BoxMesh).size =  Vector3(resolution, h_dict["h_min"], resolution)

	var grid_x = int(rect.position.x / cell_size)
	var grid_y = int(rect.position.y / cell_size)
	
	grid[ grid_x ][ grid_y ].storage[0].aabb = aabb
	
	call_deferred("add_child",occ)
	occ.connect("tree_entered", Callable(self, 
				"_on_tree_entered_occ").bind( occ,
										Vector3(rect.position.x+cell_size/2.0, 
												h_dict["h_min"]/2.0, 
												rect.position.y+cell_size/2.0),
										grid_x,
										grid_y,
										aabb))

# Runs automatically when the node is added to the scene tree

	#set_pos.call_deferred(occ,)	
	#add_child(box)
	#box.global_position = Vector3(node.position.x+resolution/2.0, h/2.0, node.position.y+resolution/2.0)	


	

func _on_tree_entered(node:Node3D,pos:Vector3):
	node.global_position = pos
	print( "added node " + node.name +" to tree at " + var_to_str(pos) )
	
func _on_tree_entered_occ(node:Node3D,pos:Vector3, i:int, j:int,aabb:AABB):
	node.global_position = pos
	print( "added node " + node.name +" to tree at " + var_to_str(pos) )
	for ch in grid[i][j].storage[0].node.get_children():
		(ch as MeshInstance3D).custom_aabb = aabb
		
func set_pos(occ,pos):
	occ.global_position = pos

var first_time:bool = true	


func setup_shader()->void:
	for ch in tiles_256.get_children():
		
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
				.set_shader_parameter("texture_height",self.height_map_texture)
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
				.set_shader_parameter("uv_scale",UV_SCALE)				
				
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("HEIGHT_SCALE",HEIGHT_SCALE)
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("normal_map",gpuNormals)
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("texture_albedo",gpuSplat)	
					
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("alb_h_1",alb_h_1)
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("alb_h_2",alb_h_2)
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("alb_h_3",alb_h_3)		
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("alb_h_4",alb_h_4)
					
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("norm_r_1",self.norm_rough_1)
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("norm_r_2",norm_rough_2)	
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("norm_r_3",norm_rough_3)	
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("norm_r_4",norm_rough_4)						

#=======================================================================================
# Standard Functions
#=======================================================================================

# Called when the node enters the scene tree for the first time.
# This really needs to cache stuff computed in the Editor and run that in the game
func _ready() -> void:

	setup_grid(grid_size)
	for i in grid_size:
		for j in grid_size:
			#grid[i][j].storage[0].aabb = AABB(Vector3(0.0, 100000, 0.0), Vector3(cell_size, 1000, cell_size))
			#grid[i][j].storage[0].aabb.end.y = -100000
			
			var dup = tiles_256.duplicate()
			add_child(dup)
			dup.global_position = Vector3(float(i)*128.0, 0.0,float(j)*128.0)
			grid[i][j].storage[0].node = dup
				
	if not Engine.is_editor_hint():
		load_image()
		
		create_collision()
	

										
	setup_shader()			
	
	
	var grid_coords = world_coords_to_grid_coords(player.global_position.x, player.global_position.z)
	self.flatten_grid_pattern_at_point(grid_coords)
	#for i in grid_size:
		#for j in grid_size:
			##grid[i][j].storage[0].aabb = AABB(Vector3(0.0, 100000, 0.0), Vector3(cell_size, 1000, cell_size))
			##grid[i][j].storage[0].aabb.end.y = -100000
			#var dup = tiles_256.duplicate()
			#add_child(dup)
			#dup.global_position = Vector3(float(i)*128.0, 0.0,float(j)*128.0)
			#for ch in dup.get_children():
#
					#
				#(ch as MeshInstance3D).custom_aabb = grid[i][j].storage[0].aabb
				# compute the AABB size
				#var aabb_size = grid[i][j].storage[0].aabb.end.y - grid[i][j].storage[0].aabb.position.y
				#(ch as MeshInstance3D).custom_aabb.size.y = aabb_size 
				#print("Custom: " + var_to_str((ch as MeshInstance3D).custom_aabb))
				#print("Actual: " + var_to_str((ch as MeshInstance3D).get_aabb()))



var tracked_x =10
var tracked_z = 10

func _process(delta: float) -> void:
	var grid_coords = world_coords_to_grid_coords(player.global_position.x, player.global_position.z)
	var moved = false
	if grid_coords.x != tracked_x:
		tracked_x = grid_coords.x
		moved = true
	if grid_coords.y != tracked_z:
		tracked_z = grid_coords.y
		moved = true
		
	if moved:
		self.flatten_grid_pattern_at_point(grid_coords)



			

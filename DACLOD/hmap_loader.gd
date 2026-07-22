
@tool
extends Node3D


@onready var tiles_256: Node3D = $tiles_256
@onready var compute_helper: Node3D = $"../ComputeHelper"
@export var compute_shader_collision:bool = false

#@onready var collision_shape_3d: CollisionShape3D = $"../StaticBody3D/CollisionShape3D"
@export var height_map_name :String = "res://assets/Heightmaps/ISLAND_4k_2/height2.exr"
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
@export var HEIGHT_SCALE:float = 500.0

#var height_data = PackedFloat32Array()

@export_tool_button("DONT CLICK THIS BUTTON")
var make_collider = create_occluders

@onready var tiles: Node3D = $tiles_256


var x: float = 0
var z: float = 0

var TEXTURE_DIVISOR= 127



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
	var colliders = []
	
var grid_pattern = [[ Vector2i(-1, -1),  Vector2i(-1, 0), Vector2i(-1, 1) ],\
					[ Vector2i( 0, -1),  Vector2i( 0, 0), Vector2i( 0, 1) ],\
					[ Vector2i( 1, -1),  Vector2i( 1, 0), Vector2i( 1, 1) ]]
	

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
			
# Applies a function to the 9 surrounding tiles.
func flatten_grid_pattern_at_point(p:Vector2i, tracked_grid_nodes: Array, b_threaded:bool)->void:
	for i in range(0,3):
		for j in range(0,3):
			# the grid pattern + global tile position
			var px = grid_pattern[ i ][ j ].x + p.x
			var py = grid_pattern[ i ][ j ].y + p.y
			# bounds check
			if px >= 0 and px < grid_size and py >= 0 and py < grid_size :
				# track
				tracked_grid_nodes.append( Vector2i( px, py) )
				# if the node has no collider
				if grid[ px ][ py ].storage[ 0 ].collider_active == false:
					# activate
					grid[ px ][ py ].storage[ 0 ].collider_active = true

					# generate
					if b_threaded:		
						var rect:Rect2
						rect.position = Vector2(float(px)*cell_size  , 
												float(py)*cell_size  )						
						rect.size = Vector2(cell_size, cell_size)	
						WorkerThreadPool.add_task(func():thread_create_colliders(rect))
					else:
						var rect:Rect2
						rect.position = Vector2(float(px)*cell_size  , 
												float(py)*cell_size  )												
						rect.size = Vector2(cell_size, cell_size)							
						thread_create_colliders(rect)

				
#=======================================================================================
# Colliders
#=======================================================================================

# wrapper for the thread
func thread_create_colliders(rect:Rect2):
	thread_generate(rect, compute_shader_collision)		
				

	
# conveniently we can declare useless variables half way down the page	
var data_mesh_grid:Dictionary
var mesh_faces :PackedVector4Array
var mesh_verts:PackedVector4Array

# this is where we initialize compute shaders, so really the function
# should be called initialize_compute_helper or something ... 
func create_occluders()->void:
	#if not Engine.is_editor_hint() and first_time:
	first_time = false

	mesh_faces = tiles.get_mesh_faces()
	mesh_verts = tiles.get_mesh_vertices()
	print(sqrt(mesh_verts.size()))

	# Launch the compute shader kernal to quickly compute the AABB's 	
	var computed_heights :PackedVector4Array= compute_helper.generate_AABB_and_occluders(hmap)
	
	#var grid_coord = world_coords_to_grid_coords(player.global_position.x, player.global_position.z)
	if compute_shader_collision:
		var verts_output :PackedVector4Array = compute_helper.generate_physics_shape( 
							hmap, 								# height map
							self.splat_map, 					# splat map (s)
							self.alb1, 							# texture arrays
							self.alb3,							# texture arrays 
							Vector2(float(15.0),float(16.0)),   # start grid location
							UV_SCALE,							# defined in @export variable
							float(channel_for_splat),			# defined in @export ...
							HEIGHT_SCALE,						# ....
							mesh_verts)							# the LOD 0 mesh vertices
				
		# this needs to be a threaded call if done in real time
		# START THREAD			
		var mesh_data_output = tiles.mesh_verts_to_faces( mesh_faces, verts_output)

		var static_body:StaticBody3D = StaticBody3D.new()
		var collision_shape := CollisionShape3D.new()
		
		var polygon_shape := ConcavePolygonShape3D.new()
		polygon_shape.set_faces(mesh_data_output)
		collision_shape.shape = polygon_shape
		static_body.add_child(collision_shape)
		#
		add_child.call_deferred(static_body)
		
		
		var rect:Rect2
		rect.position = Vector2(float(15.0)*cell_size  , 
						float(16.0)*cell_size  )						
		rect.size = Vector2(cell_size, cell_size)			
	
		static_body.connect("tree_entered", Callable(self, 
			"_on_tree_entered").bind( static_body,
									Vector3(rect.position.x  , 
											0.0, 
											rect.position.y )))							
		# END THREAD
		
	# setup the AABB for the displaced terrain chunks
	# the tiles came out of the compute shader in chunks of 64 x 64 
	# so they are merged up into 128 x 128 sized chunks
	# overall this process is very efficient compared to 
	# computing all this in gdscript							
	for J in range(63):
		if J % 2 == 0:
			for I in range(63):
				if I % 2 == 0:
					# get the 4 local data points and merge them
					# to create the AABB
					var i1 = I + J*64
					var i2 = (I+1) + J*64
					var i3 = I + (J+1)*64
					var i4 = (I+1) + (J+1)*64
					
					var v1 =[]
					v1.append( computed_heights[i1] )
					v1.append( computed_heights[i2] )
					v1.append( computed_heights[i3] )
					v1.append( computed_heights[i4] )
					
					var local_min_h = 10000.0
					var local_max_h = 0.0
					for vec in v1:
						if vec.x < local_min_h:
							local_min_h = vec.x
						if vec.y > local_max_h:
							local_max_h = vec.y
					
					var g_x = I / 2
					var g_y = J / 2
					
					var local_height = max(local_max_h - local_min_h, 1.0)
					
					grid[ g_x ][ g_y ].storage[0].aabb = AABB( Vector3(	-63.5, 
																	   	local_min_h, 
																		-63.5),
															   Vector3( cell_size,
																		local_height, 
																		cell_size) )
																		
					# set the occlusion mesh for the terrain chunk												
					var rect2:Rect2
					rect2.position = Vector2(float(g_x)*cell_size  , 
									 		 float(g_y)*cell_size   )
					rect2.size = Vector2(cell_size, cell_size)	
			
					# this looks wrong all of a sundden, perhaps
					# this works because the displacement causes a shift and
					# needs to be re-adjusted later
					var min_h = grid[ g_x ][ g_y ].storage[0].aabb.position.y
					
					var occl := OccluderInstance3D.new()
					var box_occl = BoxOccluder3D.new()
			
					# the height is the minimum coordinate of the chunk AABB
					box_occl.size = Vector3(cell_size, min_h, cell_size)
					occl.occluder = box_occl	
					
					get_parent().add_child.call_deferred(occl)
					occl.connect("tree_entered", 
						 Callable(self, 
						 		  "_on_tree_entered_computed_occ")
								  .bind( occl,
										# center the box
										 Vector3(rect2.position.x+cell_size/2.0 + 0.5, 
												 min_h/2.0, 
												 rect2.position.y+cell_size/2.0 + 0.5)))	

					# now finally set the AABB													
					for ch in grid[ g_x ][ g_y ].storage[ 0 ].node.get_children():
						(ch as MeshInstance3D).custom_aabb = grid[ g_x ][ g_y ].storage[0].aabb			
		

# set the position once the object has been added to the tree
func _on_tree_entered_computed_occ(node:Node3D,pos:Vector3):
	node.global_position = pos				
						

func create_box_mesh(pos:Vector3, size:Vector3)->MeshInstance3D:
	var occluder_mesh: = MeshInstance3D.new()
	var occluder_box_shape := BoxMesh.new()
	occluder_box_shape.size =size 
	occluder_mesh.mesh = occluder_box_shape
	occluder_mesh.global_position = pos
	return occluder_mesh
		


@export var player:CharacterBody3D


				
#=======================================================================================
# heightmap accessor functions and Images
#=======================================================================================
func load_image()->void:
	
	hmap = LoadLargeHeightMap()
	height_map_name = height_map_texture.resource_path
		
	# find the normal map or create
	var last_slash = height_map_name.rfind("/")
	var substr = height_map_name.substr(0,last_slash)
	var normal_map_path = substr + "/normal_map.png"	
	
	create_normal_map(hmap, self.HEIGHT_SCALE, normal_map_path)
	if hmap.is_compressed():
		hmap.decompress()	
	#await gpuSplat.changed
	splat_map = gpuSplat.get_image()
	if splat_map.is_compressed():
		splat_map.decompress()
	
	load_shader_images()


func load_shader_images()->void:

	alb1 = alb_h_1.get_image()
	alb2 = alb_h_2.get_image()
	alb3 = alb_h_3.get_image()
	alb4 = alb_h_4.get_image()
	
	# not sure if this needs to be done here ...
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
	


	

func LoadLargeHeightMap()->Image:
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
# NOT SERIOUS AS NORMAL MAP ISNT CURRENTLY USED ANYWHERE AND WOULD BE WRITTEN IN 
# COMPUTE SHADER 
func create_normal_map(height_map:Image, bump_scale:float, path:String)->void:
	
	gpuNormals = load(path) 
	
	if (gpuNormals == null) :#or gpuNormals.is_empty():
		nmap = height_map.duplicate(true)

		
		nmap.bump_map_to_normal_map(bump_scale)
		gpuNormals = ImageTexture.new()
		gpuNormals.create_from_image(nmap)
	
		# Save with error checking
		var save_err := nmap.save_png(path)
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
		

# This is used by the threaded cpu script collision mesh generation model 
# unfortunately this function is probably innaccurate
func sample_image_bilnear_bump(image:Image,x:float, y:float, scale:float, divisor:float, size:float)->float:
	
	var u_1 = scale * x / divisor  
	var v_1 = scale * y / divisor 
		
	var u__1 =  (u_1 - int(u_1))
	var v__1 =    (v_1 - int(v_1))
	
	var u1 = size * u__1
	var v1 = size * v__1
		
	var u12 = u1 + 1 
	if u12 > size-1: u12 = 0
	var v12 = v1 + 1
	if v12 > size-1: v12 = 0

	# bilinear filter attempt 
	var m_uv1 := Vector2i( u1,v1)
	var m_uv12 := Vector2i( u12,v1)
	var m_uv13 := Vector2i( u1,v12)
	var m_uv14 := Vector2i( u12,v12)
	var disp11 = image.get_pixelv( m_uv1 ).a	
	var disp12 = image.get_pixelv( m_uv12 ).a
	var disp13 = image.get_pixelv( m_uv13 ).a
	var disp14 = image.get_pixelv( m_uv14 ).a
	var disp1 = lerp ( lerp(disp11,disp12,u__1), lerp(disp13,disp14,u__1), v__1)	

	return disp1

@export var channel_for_splat:int

func get_map_values( x:float, z:float, X:int, Z:int):
	var normal_pix:Color = nmap.get_pixel(X+int(x), Z+int(z))
	
	var H1 = HEIGHT_SCALE*hmap.get_pixel(X + int(x-1), Z + int(z)).r
	var H2 = HEIGHT_SCALE*hmap.get_pixel(X + int(x+1), Z + int(z)).r
	var H3 = HEIGHT_SCALE*hmap.get_pixel(X + int(x), Z + int(z-1)).r
	var H4 = HEIGHT_SCALE*hmap.get_pixel(X + int(x), Z + int(z+1)).r
	
	var normal = -Vector3(2.0*(H2 - H1), -4.0, 2.0*(H4-H3) ).normalized();
	
	var splat:Color = splat_map.get_pixel( X+int(x), Z+int(z) )

	# MAP 1 of 4
	var disp1 =sample_image_bilnear_bump(alb1,x,z,UV_SCALE.x,128.0,512)

	# MAP 2 of 4
	var u2 = 	int(512.0*(x * UV_SCALE.x/ TEXTURE_DIVISOR  - floor(x * UV_SCALE.x/ TEXTURE_DIVISOR  ) ))
	var v2 = 	int(512.0*(z * UV_SCALE.x/ TEXTURE_DIVISOR  - floor(z * UV_SCALE.x/ TEXTURE_DIVISOR  ) ))
	var m_uv2:= Vector2i( u2,v2 )
	var disp2 = alb2.get_pixelv( m_uv2 ).a	
	
	# MAP 3 of 4
	var disp3 =sample_image_bilnear_bump(alb3,x,z,UV_SCALE.z,128.0,512)

	# MAP 4 of 4
	var u4 = 	int( 512.0 * fposmod( (x * UV_SCALE.w)/ TEXTURE_DIVISOR, 1.0  )) 
	var v4 = 	int( 512.0 * fposmod( (z * UV_SCALE.w)/ TEXTURE_DIVISOR, 1.0  )) 
	var m_uv4:= Vector2i( u4,v4 )
	var disp4 = alb4.get_pixelv( m_uv4 ).a	
	
	var splat_pixel = get_splat_color(splat)	
	
	# The function is only using MAP 1 and MAP 3
	var hval:float = (splat_pixel* disp1 +(1.0 -splat_pixel) * disp3)			
	
	return {
		"normal":normal,
		"height":hval
	}

func get_splat_color(splat)->float:
	if channel_for_splat == 0:
		return splat.r
	if channel_for_splat == 1:
		return splat.g
	if channel_for_splat == 2:
		return splat.b
	return splat.a		

#=======================================================================================
# Thread function
#=======================================================================================	
func thread_generate(rect: Rect2, use_compute:bool)->void:
	# if this is true then the process is not multi threaded
	if use_compute:
		var verts_output :PackedVector4Array = compute_helper.generate_physics_shape_per_frame( hmap, 
							self.splat_map, 
							self.alb1, 
							self.alb3, 
							Vector2(rect.position.x/128.0,rect.position.y/128.0),
							UV_SCALE,
							float(channel_for_splat),
							HEIGHT_SCALE,
							mesh_verts)
						
		WorkerThreadPool.add_task(func():setup_computed_collision_model(rect,mesh_faces, verts_output))	
					
	else:						
#
		var mesh_data = generate_mesh_data(rect)

		var static_body:StaticBody3D = StaticBody3D.new()
		var collision_shape := CollisionShape3D.new()
		
		var polygon_shape := ConcavePolygonShape3D.new()
		polygon_shape.set_faces(mesh_data)

	#create_physics_shape.call_deferred(mesh_data,
									   #Vector3( rect.position.x , 
												#0.0, 
												#rect.position.y ))
		collision_shape.shape = polygon_shape
		static_body.add_child(collision_shape)
		#
		add_child.call_deferred(static_body)
		#
		#
		#
		static_body.connect("tree_entered", Callable(self, 
			"_on_tree_entered").bind( static_body,
									Vector3(rect.position.x  , 
											0.0, 
											rect.position.y )))
		
		
#=======================================================================================
# Colliosion Mesh
#=======================================================================================	

func setup_computed_collision_model(rect: Rect2,
									mesh_faces:PackedVector4Array,			# are these passed by reference 
									mesh_verts_disp:PackedVector4Array):	# or copied to the thread
										
	var mesh_data_output = tiles.mesh_verts_to_faces(mesh_faces, mesh_verts_disp)

	var static_body:StaticBody3D = StaticBody3D.new()
	var collision_shape := CollisionShape3D.new()
		
	var polygon_shape := ConcavePolygonShape3D.new()
	polygon_shape.set_faces(mesh_data_output)

	#create_physics_shape.call_deferred(mesh_data,
									   #Vector3( rect.position.x , 
												#0.0, 
												#rect.position.y ))
	collision_shape.shape = polygon_shape
	static_body.add_child(collision_shape)
		#
	add_child.call_deferred(static_body)

	static_body.connect("tree_entered", Callable(self, 
			"_on_tree_entered").bind( static_body,
								Vector3(rect.position.x  , 
										0.0, 
										rect.position.y )))		
												

#=======================================================================================
# CPU Collision Mesh ( probably redundant )
#=======================================================================================	
func generate_mesh_data(rect: Rect2) -> Array:

	var mesh_faces_local :PackedVector3Array=  PackedVector3Array()
	
	for v in mesh_faces:
		v.y = get_altitude(Vector3(rect.position.x+v.x, 0, rect.position.y+v.z))
		var disp_dict = get_map_values(v.x, v.z, rect.position.x, rect.position.y)#x/2.0,z/2.0
		var v1 =Vector3(v.x, v.y, v.z)
		v1 += 5.0 * disp_dict["normal"] * disp_dict["height"]# - 2.5 * disp_dict["normal"]
		mesh_faces_local.append(v1)
		
	return mesh_faces_local	



#=======================================================================================
# function that gets called when nodes are added to the tree
#=======================================================================================
func _on_tree_entered(node:Node3D,pos:Vector3):
	node.global_position = pos
	var grid_coord =  world_coords_to_grid_coords( pos.x, pos.z ) 
	grid[ grid_coord.x ][ grid_coord.y ].colliders.append( node )

	
#=======================================================================================
# Physics Shape (NOT WORKING)
#=======================================================================================
func create_physics_shape( data:PackedVector3Array, pos:Vector3) ->void:
	# 1. Create a box shape
	
	var shape_rid = PhysicsServer3D.concave_polygon_shape_create()
	var mesh_data = { "faces": data, "back_face_collision": false}
	PhysicsServer3D.shape_set_data(shape_rid, mesh_data) 
	# 2. Create a rigid body
	var body_rid = PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(body_rid, PhysicsServer3D.BODY_MODE_STATIC)
	# 3. Assign the shape to the body
	PhysicsServer3D.body_add_shape(body_rid, shape_rid)
	# 4. Set the body’s transform (position in world)
	var transform = Transform3D(Basis(), pos)
	PhysicsServer3D.body_set_state(body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM, transform)
	# 5. Add the body to the space
	var space = get_world_3d().space
	PhysicsServer3D.body_set_space(body_rid, space)
	
		

var first_time:bool = true	

#=======================================================================================
# Shader
#=======================================================================================
func setup_shader()->void:
	for ch in tiles_256.get_children():
		
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
				.set_shader_parameter("texture_height",self.height_map_texture)
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
				.set_shader_parameter("uv_scale",UV_SCALE)	
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
				.set_shader_parameter("channel_for_splat",channel_for_splat)			
						
				
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("HEIGHT_SCALE",HEIGHT_SCALE)
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("normal_map",gpuNormals)
		((ch as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial)\
					.set_shader_parameter("splat_tex",gpuSplat)	
					
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
			# duplicate the tile meshes in a grid pattern
			var dup = tiles_256.duplicate()
			add_child(dup)
			dup.global_position = Vector3( float( i ) * cell_size, # cell_size is also set by the mesh size
										   0.0, 
										   float( j ) * cell_size)
			
			grid[ i ][ j ].storage[0].node = dup
				
				
	load_image()
					
	setup_shader()			
	
	create_occluders()
	
	var grid_coords = world_coords_to_grid_coords(player.global_position.x, player.global_position.z)
	#self.flatten_grid_pattern_at_point(grid_coords, tracked_grid_nodes,false)


var tracked_x =0
var tracked_z =0
var tracked_grid_nodes :Array[Vector2i]= []

func _process(delta: float) -> void:
	var grid_coords = world_coords_to_grid_coords(player.global_position.x, player.global_position.z)
	var moved = false
	var moved_x = false
	var moved_z = false
	var old_x = tracked_x
	var old_z = tracked_z
	if grid_coords.x != tracked_x:
		tracked_x = grid_coords.x
		moved = true
		moved_x = true
	if grid_coords.y != tracked_z:
		tracked_z = grid_coords.y
		moved = true
		moved_z = true
		
	# this is supposed to free up the old collision nodes that are out of range, but
	# the debug view shows they're still active.
	if moved_x:
		var offset = 1 if old_x > tracked_x else -1
		for k in tracked_grid_nodes.size():
			
			if ( tracked_grid_nodes[ k ].x == old_x + offset) :
				for col in grid [ tracked_grid_nodes[ k ].x ][ tracked_grid_nodes[ k ].y ].colliders:
					col.queue_free()
				grid [ tracked_grid_nodes[ k ].x ][ tracked_grid_nodes[ k ].y ].colliders.clear()
				grid [ tracked_grid_nodes[ k ].x ][ tracked_grid_nodes[ k ].y ].storage[0].collider_active = false	

	if moved_z:
		var offset = 1 if old_z > tracked_z else -1
		for k in tracked_grid_nodes.size():
			if ( tracked_grid_nodes[ k ].y == old_z + offset) :
				for col in grid [ tracked_grid_nodes[ k ].x ][ tracked_grid_nodes[ k ].y ].colliders:
					col.queue_free()
				grid [ tracked_grid_nodes[ k ].x ][ tracked_grid_nodes[ k ].y ].colliders.clear()
				grid [ tracked_grid_nodes[ k ].x ][ tracked_grid_nodes[ k ].y ].storage[0].collider_active = false	
		
		
	if moved:
							 		
		tracked_grid_nodes.clear()			
		# generate collision chunks near the player ... the current chunk should already
		# be generated and the player shouldn't have time to run faster than the thread
		self.flatten_grid_pattern_at_point(grid_coords,tracked_grid_nodes, !compute_shader_collision )






	

	

	

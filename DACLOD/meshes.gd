@tool
extends Node3D



#@onready var plane__128: MeshInstance3D = $Plane__128

@onready var plane_001: MeshInstance3D = $Plane_001
@onready var plane_002: MeshInstance3D = $Plane_002
@onready var plane_003: MeshInstance3D = $Plane_003
@onready var plane_004: MeshInstance3D = $Plane_004
@onready var plane_005: MeshInstance3D = $Plane_005
@onready var plane__128: MeshInstance3D = $Plane_006
var plane_006 = plane__128

func get_lod( lod_num: int )->MeshInstance3D:
	
	match lod_num:
		0:
			return plane__128
		1:
			return plane_005
		2: 
			return plane_004
		3:
			return plane_003
		4:
			return plane_002
		5:
			return plane_001
			
	return plane_006
		

func get_mesh_faces()->PackedVector4Array:
	var faces:PackedVector4Array = PackedVector4Array()
	var mdt := MeshDataTool.new()
	var mesh = plane__128.mesh
	for surface in mesh.get_surface_count():
		var err := mdt.create_from_surface(mesh, surface)
		if err != OK:
			print("Failed to read surface %d" % surface)
			continue

		# Extract indices (faces are always triangles)
		var face_count := mdt.get_face_count()
		for f in face_count:
			var i1 := mdt.get_face_vertex(f, 0)
			var i2 := mdt.get_face_vertex(f, 1)
			var i3 := mdt.get_face_vertex(f, 2)

			var vec1 = mdt.get_vertex(i1)
			var vec2 = mdt.get_vertex(i2)
			var vec3 = mdt.get_vertex(i3)
			
			var v1 = Vector4(vec1.x,vec1.y,vec1.z,1.0)
			var v2 = Vector4(vec2.x,vec2.y,vec2.z,1.0)
			var v3 = Vector4(vec3.x,vec3.y,vec3.z,1.0)
			faces.append(v1)
			faces.append(v2)
			faces.append(v3)

		mdt.clear()	
	
	return faces

func mesh_verts_to_faces(mesh_faces:PackedVector4Array,mesh_verts_disp:PackedVector4Array)->PackedVector3Array:
	var faces:PackedVector3Array = PackedVector3Array()
	var mdt := MeshDataTool.new()
	var mesh = plane__128.mesh
	for surface in mesh.get_surface_count():
		var err := mdt.create_from_surface(mesh, surface)
		if err != OK:
			print("Failed to read surface %d" % surface)
			continue

		# Extract indices (faces are always triangles)
		var face_count := mdt.get_face_count()
		for f in face_count:
			var i1 := mdt.get_face_vertex(f, 0)
			var i2 := mdt.get_face_vertex(f, 1)
			var i3 := mdt.get_face_vertex(f, 2)

			var v1 = mesh_verts_disp[i1]
			var v2 = mesh_verts_disp[i2]
			var v3 = mesh_verts_disp[i3]
			

			faces.append(Vector3(v1.x,v1.y,v1.z))
			faces.append(Vector3(v2.x,v2.y,v2.z))
			faces.append(Vector3(v3.x,v3.y,v3.z))


	return faces	
	
	# Reads all vertices and indices from every surface of a Mesh
func get_mesh_vertices() -> PackedVector4Array:
	var mesh = plane__128.mesh
	var result := PackedVector4Array()
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
			result.append(Vector4(vert.x, vert.y, vert.z, 1.0))
			
	return result	
	
	# Reads all vertices and indices from every surface of a Mesh
func get_mesh_vertices_and_indices() -> Dictionary:
	
	var mesh = plane__128.mesh
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

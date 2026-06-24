extends CharacterBody3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	velocity = Vector3.ZERO
	if Input.is_action_pressed("pitch_down"):
		velocity =  -global_basis.z *20.0
	if Input.is_action_pressed("pitch_up"):
		velocity = global_basis.z *20.0 		


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		rotate_object_local(Vector3(1.0,0.0,0.0),-event.relative.y *0.005)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity()
	else:
		velocity.y = 0.0
	move_and_slide()



#func _generate_mesh(segment_count: int):
	#var st = SurfaceTool.new()
	#st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	#st.set_color(Color(0, 1, 0))
#
	#var previous_noise: float = 0.0 
	#var x_vert_pos = 1
	#var y_vert_pos = 0
	#var z_vert_pos = 1 
#
	#for i in segment_count:
		##Noise offset for yPos
		#y_vert_pos = noise.get_noise_2d(i, 0.0) * 100 
#
		#st.add_vertex(Vector3(-x_vert_pos, y_vert_pos, z_vert_pos))
		#st.add_vertex(Vector3(x_vert_pos, y_vert_pos, z_vert_pos))
		#z_vert_pos += 2
#
	#mesh = st.commit()
	#mesh.create_trimesh_shape() 

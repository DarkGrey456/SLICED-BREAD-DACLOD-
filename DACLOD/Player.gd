extends CharacterBody3D
@onready var camera_3d: Camera3D = $SpringArm3D/Camera3D
@export var SPEED = 10.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	velocity = Vector3.ZERO





func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (camera_3d.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = direction * SPEED
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

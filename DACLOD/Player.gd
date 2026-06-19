extends CharacterBody3D



func _process(delta: float) -> void:
	if Input.is_action_pressed("pitch_down"):
		velocity =  -global_basis.z *100.0
	if Input.is_action_pressed("pitch_up"):
		velocity = global_basis.z *100.0 		


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

extends Camera3D


func _process(delta: float) -> void:
	if Input.is_action_pressed("pitch_down"):
		global_position -= global_basis.z *20.0
	if Input.is_action_pressed("pitch_up"):
		global_position += global_basis.z *20.0 		


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		rotate_object_local(Vector3(1.0,0.0,0.0),-event.relative.y *0.005)

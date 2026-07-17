extends SpringArm3D


# Called when the node enters the scene tree for the first time.


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		rotate_object_local(Vector3(1.0,0.0,0.0),-event.relative.y *0.005)
		

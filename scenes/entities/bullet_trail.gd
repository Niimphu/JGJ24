extends Line2D

@export var trail_length := 25
var point := Vector2()

func _process(_delta):
	global_position = Vector2.ZERO
	global_rotation = 0
	
	point = get_parent().global_position
	
	add_point(point)
	while get_point_count() > trail_length:
		remove_point(0)

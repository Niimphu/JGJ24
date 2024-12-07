extends Node2D

@onready var Light1: GradientTexture2D = $PointLight2D.texture
@onready var Light2: GradientTexture2D = $PointLight2D2.texture

@onready var default_size1 := Light1.height
@onready var default_size2 := Light2.height


func _on_timer_timeout():
	var size_1: = default_size1 + RNG.random_int(10) - 5
	var tween := get_tree().create_tween()
	tween.tween_property(Light1, "height", size_1, 0.2)
	var tween2 := get_tree().create_tween()
	tween2.tween_property(Light1, "width", size_1, 0.2)
	
	var size_2: = default_size2 + RNG.random_int(14) - 7
	var tween3 := get_tree().create_tween()
	tween3.tween_property(Light2, "height", size_2, 0.2)
	var tween4 := get_tree().create_tween()
	tween4.tween_property(Light2, "width", size_2, 0.2)

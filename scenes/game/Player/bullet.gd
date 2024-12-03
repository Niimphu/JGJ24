extends Area2D

var speed = 2500

var bullet_direction

func _process(delta: float) -> void:
	position -= bullet_direction * speed * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
	print("gone")

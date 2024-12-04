extends Area2D

var speed := 1000
var bullet_direction: Vector2
var shoot := false

func set_direction(direction: Vector2) -> void:
	await ready
	bullet_direction = direction
	shoot = true


func _process(delta: float) -> void:
	if !shoot:
		return
	position -= bullet_direction * speed * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
	print("bullet deleted offscreen")

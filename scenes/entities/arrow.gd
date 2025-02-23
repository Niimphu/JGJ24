extends Area2D

var direction := Vector2.ZERO
var speed := 365



func _physics_process(delta):
	global_position += direction * speed * delta


func set_parameters(new_direction: Vector2):
	direction = new_direction.normalized()
	look_at(direction)
	await get_tree().create_timer(3).timeout
	queue_free()


func _on_area_entered(area: Node2D):
	if area.name == "PlayerHurtbox":
		EventBus.player_hit.emit(-4, global_position + Vector2(2, -10))
	queue_free()

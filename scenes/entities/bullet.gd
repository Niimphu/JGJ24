extends Area2D

var speed := 1000
var bullet_direction: Vector2
var shoot := false
var count = 0
var hit_counter = 0
signal two_enemies_hit



func _ready():
	connect("area_entered", Callable(self, "_on_area_entered"))


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


func _on_area_entered(area: Area2D):
	if area.name == "TerrainHurtbox":
		queue_free()
	else:
		hit_counter += 1
		if hit_counter >= 2:
			emit_signal("two_enemies_hit")
			queue_free()

extends Area2D

var speed := 850
var bullet_direction: Vector2
var shoot := false
var count := 0
var enemies_hit := 0
var piercing_level := 2
signal two_enemies_hit


func _ready():
	#connect("area_entered", Callable(self, "_on_area_entered"))
	area_entered.connect(_on_area_entered)


func set_parameters(direction: Vector2, piercing: int = 2) -> void:
	await ready
	bullet_direction = direction
	piercing_level = piercing
	shoot = true


func _physics_process(delta: float) -> void:
	if !shoot:
		return
	position -= bullet_direction * speed * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_area_entered(area: Area2D):
	if area.name == "TerrainHurtbox":
		queue_free()
	else:
		enemies_hit += 1
		if enemies_hit >= piercing_level:
			emit_signal("two_enemies_hit")
			queue_free()

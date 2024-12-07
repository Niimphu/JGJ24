extends Area2D

var speed := 850
var bullet_direction: Vector2
var shoot := false
var count := 0
var hit_count := 0
var piercing_level := 2
var enemies_hit: Array
var multiplier:= 0


func _ready():
	#connect("area_entered", Callable(self, "_on_area_entered"))
	area_entered.connect(_on_area_entered)
	EventBus.up_mult.connect(_up_mult)


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
	elif enemies_hit.has(area):
		return
	else:
		enemies_hit.append(area)
		hit_count += 1
		if hit_count >= piercing_level:
			queue_free()


func _up_mult():
	multiplier += 1
	

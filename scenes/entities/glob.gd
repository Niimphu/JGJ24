extends Area2D

@onready var Animator := $AnimationPlayer

var Player: CharacterBody2D

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	global_position = Player.global_position + Vector2(0, -0.5)


func set_parameters(player_scene: CharacterBody2D):
	Player = player_scene
	set_physics_process(true)
	Animator.play("glob")
	await get_tree().create_timer(0.7).timeout


func _on_area_entered(_body):
	EventBus.player_hit.emit(-4, global_position + Vector2(2, -10))


func stop_moving() -> void:
	set_physics_process(false)


func die():
	queue_free()

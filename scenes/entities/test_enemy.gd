extends CharacterBody2D

var speed := 80
var id := 1

@export var player: Node2D
@onready var Navigator := $NavigationAgent2D

func _physics_process(_delta):
	print(Navigator.get_next_path_position())
	var direction: Vector2 = to_local(Navigator.get_next_path_position()).normalized()
	velocity = direction * speed
	move_and_slide()
	
	if Engine.get_physics_frames() % 30 != id:
		return
	find_path()


func find_path() -> void:
	Navigator.target_position = player.global_position

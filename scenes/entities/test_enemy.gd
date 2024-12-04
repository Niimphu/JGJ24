extends CharacterBody2D

@onready var player = get_parent().get_parent().get_node("Player")

var speed = 2000
var player_position
var target_position
var hit_count = 0

func _physics_process(delta: float) -> void:
	
	player_position = player.position
	target_position = (player_position - position).normalized()
	if position.distance_to(player_position) > 10:
		velocity = target_position * speed * delta
		move_and_slide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	queue_free()

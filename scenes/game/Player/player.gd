extends CharacterBody2D

enum {
	MOVE,
	DASH
}

@onready var bullet_scene = preload("res://Player/bullet.tscn")
const SPEED = 700
const FRICTION = 800
var state = MOVE
var dash_vector = Vector2.LEFT


func _physics_process(delta: float) -> void:
	match state:
		MOVE:
			move_state(delta)
		DASH:
			dash_state(delta)
	if Input.is_action_just_pressed("fire"):
		shoot()

func move_state(delta):
	var input_vector = Vector2.ZERO

	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		dash_vector = input_vector
		velocity = input_vector * SPEED
	else:
		velocity = velocity.move_toward(input_vector, FRICTION)
	move_and_slide()
	if Input.is_action_just_pressed("dash"):
		state = DASH

#this shortens the dash when 
func dash_state(delta):
	velocity = dash_vector * 5000
	move_and_slide()
	roll_animation_finished()

func roll_animation_finished():
	state = MOVE


func	shoot():
	var bullet = bullet_scene.instantiate()
	bullet.position = position
	bullet.bullet_direction = (position - get_global_mouse_position()).normalized()
	get_parent().add_child(bullet)

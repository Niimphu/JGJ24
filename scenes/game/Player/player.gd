extends CharacterBody2D

enum {
	MOVE,
	ROLL
}

@onready var bullet_scene = preload("bullet.tscn")
const SPEED = 700
const FRICTION = 800
var state = MOVE

#still assumes roll to the left without prior input, needs fixing
var roll_vector = Vector2.LEFT


func _physics_process(delta: float) -> void:
	match state:
		MOVE:
			move_state()
		ROLL:
			roll_state()
	if Input.is_action_just_pressed("fire"):
		shoot()

#needs delta so speed isn't tied to FPS
func move_state():
	var input_vector = Vector2.ZERO

	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		velocity = input_vector * SPEED
	else:
		velocity = velocity.move_toward(input_vector, FRICTION)
	move_and_slide()
	if Input.is_action_just_pressed("roll"):
		state = ROLL

#this shortens the roll while moving, needs fixing
#needs delta so speed isn't tied to fps
func roll_state():
	velocity = roll_vector * 5000
	move_and_slide()
	roll_animation_finished()

func roll_animation_finished():
	state = MOVE


func	shoot():
	var bullet = bullet_scene.instantiate()
	bullet.position = position
	bullet.bullet_direction = (position - get_global_mouse_position()).normalized()
	get_parent().add_child(bullet)

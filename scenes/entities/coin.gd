extends Area2D

@onready var Coin := $Coin
@onready var Animator := $AnimationPlayer

var speed := 300
var friction := 220
var direction := Vector2.ZERO
var number := 0
var rotateness := 0.2

func _ready():
	set_physics_process(false)
	area_entered.connect(be_shot)
	Animator.animation_finished.connect(die)
	var tween := get_tree().create_tween()
	var spins: int = 10 + (RNG.random_int(5))
	if RNG.random_int(2) == 1:
		spins *= -1
	speed -= RNG.random_int(20)
	tween.tween_property(Coin, "rotation", spins, 1.5)


func _physics_process(delta):
	global_position += direction * speed * delta
	speed -= friction * delta


func set_parameters(mouse_pos: Vector2, id: int):
	number = id
	direction = (mouse_pos - global_position).normalized()
	var rotate_factor := rotateness if id % 2 else -rotateness
	direction = direction.rotated(id * (rotate_factor + RNG.random_weight() / 5))
	set_physics_process(true)


func be_shot(area):
	if area.name != "Bullet":
		return
	speed = 0
	set_physics_process(false)
	Animator.play("boom")


func die(_anim_name = "bruh"):
	queue_free()

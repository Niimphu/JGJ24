extends Area2D

@onready var Coin := $Coin
@onready var Animator := $AnimationPlayer
@onready var Hitbox := $Hitbox
@onready var HitboxShape := $Hitbox/CollisionShape2D
@onready var Explosion := $Hitbox/Sprite2D

var speed := 300
var friction := 220
var direction := Vector2.ZERO
var number := 0
var rotateness := 0.2
var return_money := false

func _ready():
	set_physics_process(false)
	area_entered.connect(enemy_hit)
	Animator.animation_finished.connect(die)
	Hitbox.area_entered.connect(free_money)
	var tween := get_tree().create_tween()
	var spins: int = 10 + (RNG.random_int(5))
	if RNG.random_int(2) == 1:
		spins *= -1
	speed -= RNG.random_int(20)
	tween.tween_property(Coin, "rotation", spins, 1.5)


func _physics_process(delta):
	global_position += direction * speed * delta
	speed -= friction * delta


func set_parameters(mouse_pos: Vector2, id: int, returns: bool, big: bool):
	number = id
	return_money = returns
	direction = (mouse_pos - global_position).normalized()
	if big:
		HitboxShape.scale = Vector2(2, 2)
		Explosion.scale = Vector2(2, 2)
	
	var rotate_factor := rotateness if id % 2 else -rotateness
	direction = direction.rotated(id * (rotate_factor + RNG.random_weight() / 5))
	set_physics_process(true)


func enemy_hit(_area):
	Coin.set_deferred("disabled", true)
	speed = 0
	set_physics_process(false)
	Animator.play("boom")


func free_money(_area) -> void:
	if return_money:
		return_money = false
	else:
		return
	EventBus.explosion_money.emit(global_position)


func die(_anim_name = "bruh"):
	queue_free()

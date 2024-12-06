extends CharacterBody2D

enum {
	IDLE,
	MOVE,
	ROLL
}

@export var BulletManager: Node2D
@export var Game: Node2D
@export var AmmoCount: TextureProgressBar

@onready var Animator := $AnimationPlayer
@onready var GunAnimator := $Gun/AnimationPlayer
@onready var Body := $Body
@onready var Arm := $Gun
@onready var Jacket := $Jacket
@onready var Shadow := $Shadow
@onready var Collider := $CollisionShape2D
@onready var Sound := $Sound

@onready var bullet_scene := preload("bullet.tscn")
@onready var dust_scene := preload("res://scenes/entities/roll_dust.tscn")


const SPEED := 160
const ROLL_MULT := 3.2
const ROLL_FRICTION := 1200
var state := IDLE
var direction := Vector2.ZERO
var mouse_pos: Vector2
var roll_cd: bool = true
var reloading := false

var max_ammo := 6
var current_ammo := 6

# this is fine & whatever
var roll_direction := Vector2.RIGHT
var muzzle_pos := Vector2.ZERO
var resuming := false


func _ready():
	Animator.animation_finished.connect(finished_animation)


func _physics_process(delta: float) -> void:
	if resuming:
		resuming = false
		return
	
	mouse_pos = get_global_mouse_position()
	get_input_direction()
	muzzle_pos = Arm.global_position + (mouse_pos - Arm.global_position).normalized() * 8.5
	
	if Input.is_action_just_pressed("roll") and roll_cd and Game.update_coins(-3, popup_pos()):
		roll_cd = false
		reloading = false
		roll_pressed()
		await get_tree().create_timer(0.6).timeout
		roll_cd = true
	
	match state:
		IDLE:
			idle()
			gun_input()
		MOVE:
			move()
			gun_input()
		ROLL:
			roll(delta)


func gun_input() -> void:
	if Input.is_action_just_pressed("fire"):
		shoot()
	elif Input.is_action_just_pressed("reload"):
		reload()


func idle() -> void:
	move_arm()
	if direction != Vector2.ZERO:
		state = MOVE
		Animator.play("run")


func get_input_direction() -> void:
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	direction = direction.normalized()
	
	if direction != Vector2.ZERO and state != ROLL: # set roll direction to last non-zero direction
		roll_direction = direction


func move() -> void:
	move_arm()
	velocity = direction * SPEED
	move_and_slide()
	if direction == Vector2.ZERO:
		state = IDLE
		Animator.play("idle")


func roll_pressed() -> void:
	state = ROLL
	velocity = roll_direction * SPEED * ROLL_MULT
	Animator.play("roll")
	
	var dust_instance := dust_scene.instantiate()
	dust_instance.global_position = global_position
	get_parent().add_child(dust_instance)


func roll(delta) -> void:
	if velocity.x > 0:
		sprite_flip(false)
	else:
		sprite_flip(true)
	Jacket.visible = false
	#turn off hurtbox for i frames
	velocity = velocity.move_toward(Vector2.ZERO, ROLL_FRICTION * delta)
	move_and_slide()


func move_arm() -> void:
	Arm.look_at(mouse_pos)
	if mouse_pos.x > global_position.x:
		sprite_flip(false)
		Arm.offset.x = 4.5
		Arm.position.x = -2.1
	else:
		sprite_flip(true)
		Arm.position.x = 2.1
		Arm.offset.x = -4.5
		Arm.rotate(PI)


func finished_animation(anim_name: String) -> void:
	if anim_name == "roll":
		Jacket.visible = true
		state = IDLE
		#turn hurbox back on
		Animator.play("idle")


func sprite_flip(flip: bool) -> void:
	Body.flip_h = flip
	Arm.flip_h = flip
	if flip:
		Body.position.x = -3.3
	else:
		Body.position.x = 5


func shoot() -> void:
	if current_ammo == 0:
		Sound.empty()
		return
	
	reloading = false
	Sound.shoot()
	current_ammo -= 1
	AmmoCount.value = current_ammo
	
	var bullet := bullet_scene.instantiate()
	bullet.position = muzzle_pos
	bullet.set_parameters((position - mouse_pos).normalized())
	BulletManager.add_child(bullet)
	bullet.connect("two_enemies_hit", Callable(self, "_on_two_enemies_hit")) #check if signal has been emitted to update max_ammo
	GunAnimator.play("shoot")


func _on_two_enemies_hit():
	current_ammo += 1
	AmmoCount.value = current_ammo


func reload() -> void:
	if state == ROLL or reloading:
		return
	reloading = true
	reload_bullet()


func reload_bullet() -> void:
	if current_ammo >= max_ammo or resuming:
		reloading = false
		return
	
	GunAnimator.play("reload")
	await get_tree().create_timer(0.4).timeout
	if state == ROLL or Game.update_coins(-2, popup_pos()) == false:
		reloading = false
		return
	current_ammo += 1
	AmmoCount.value = current_ammo
	if reloading:
		reload_bullet()


func popup_pos() -> Vector2:
	return global_position + Vector2(4, -25)


func resume() -> void:
	resuming = true
	reload()
	set_process(true)

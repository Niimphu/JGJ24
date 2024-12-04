extends CharacterBody2D

enum {
	IDLE,
	MOVE,
	ROLL
}

@export var BulletManager: Node2D

@onready var Animator := $AnimationPlayer
@onready var GunAnimator := $Gun/AnimationPlayer
@onready var Body := $Body
@onready var Arm := $Gun
@onready var Jacket := $Jacket

@onready var bullet_scene := preload("bullet.tscn")
@onready var dust_scene := preload("res://scenes/entities/roll_dust.tscn")


const SPEED := 180
const ROLL_MULT := 2.5
const ROLL_FRICTION := 800
var state := IDLE
var direction := Vector2.ZERO
var mouse_pos: Vector2
var roll_cd: bool = true
var stored_ammo = 10
var ammo_in_chamber = 6
var ammo_needed = 0

# this is fine & whatever
var roll_direction := Vector2.RIGHT


func _ready():
	Animator.animation_finished.connect(finished_animation)


func _physics_process(delta: float) -> void:
	mouse_pos = get_global_mouse_position()
	get_input_direction()
	
	if Input.is_action_just_pressed("roll") and roll_cd:
		roll_cd = false
		roll_pressed()
		await get_tree().create_timer(0.5).timeout
		roll_cd = true
	
	match state:
		IDLE:
			idle()
		MOVE:
			move()
		ROLL:
			roll(delta)
	
	if state != ROLL:
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
	
	if direction != Vector2.ZERO: # set roll direction to last non-zero direction
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
	velocity -= roll_direction * ROLL_FRICTION * delta
	move_and_slide()


func move_arm() -> void:
	Arm.look_at(mouse_pos)
	if mouse_pos.x > global_position.x:
		sprite_flip(false)
		Arm.offset.x = 4.5
		Arm.position.x = -6
	else:
		sprite_flip(true)
		Arm.offset.x = -4.5
		Arm.position.x = 6
		Arm.rotate(PI)


func finished_animation(anim_name: String) -> void:
	if anim_name == "roll":
		Jacket.visible = true
		state = IDLE
		Animator.play("idle")


func sprite_flip(flip: bool) -> void:
	Body.flip_h = flip
	Arm.flip_h = flip
	if flip:
		Jacket.position.x = -4.8
	else:
		Jacket.position.x = -7.8


func shoot() -> void:
	if ammo_in_chamber > 0:
		ammo_in_chamber -= 1
		var bullet := bullet_scene.instantiate()
		bullet.position = Arm.global_position + (mouse_pos - Arm.global_position).normalized() * 8.5
		bullet.set_direction((position - mouse_pos).normalized())
		BulletManager.add_child(bullet)
		GunAnimator.play("shoot")


func reload() -> void:
	if stored_ammo > 0:
		ammo_needed = 6 - ammo_in_chamber
		if stored_ammo >= ammo_needed:
			stored_ammo -= ammo_needed
			ammo_in_chamber = 6
		elif ammo_needed >= stored_ammo:
			ammo_in_chamber += stored_ammo
			stored_ammo = 0
			GunAnimator.play("reload")
		print(ammo_in_chamber)
		print(stored_ammo)

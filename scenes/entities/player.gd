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
@onready var Hurtbox := $PlayerHurtbox
@onready var ReloadTimer := $Gun/Reload
@onready var FullReloadTimer := $Gun/FullReload

@onready var bullet_scene := preload("bullet.tscn")
@onready var dust_scene := preload("res://scenes/entities/roll_dust.tscn")


const ROLL_MULT := 3
const ROLL_FRICTION := 800
var speed := 120
var state := IDLE
var direction := Vector2.ZERO
var mouse_pos: Vector2
var roll_cd: bool = true
var reloading := false

var max_ammo := 6
var current_ammo := 6
var reload_cost := -2
var roll_cost := -3
var piercing_level := 2

# this is fine & whatever
var roll_direction := Vector2.RIGHT
var muzzle_pos := Vector2.ZERO
var resuming := false
var fully_reloadable := false


func _ready():
	Hurtbox.area_entered.connect(_on_hurtbox_entered)
	Animator.animation_finished.connect(finished_animation)
	#EventBus.player_death.connect(player_died)


func _physics_process(delta: float) -> void:
	if resuming:
		resuming = false
		return
	
	mouse_pos = get_global_mouse_position()
	get_input_direction()
	muzzle_pos = Arm.global_position + (mouse_pos - Arm.global_position).normalized() * 8.5
	
	if Input.is_action_just_pressed("roll") and roll_cd and Game.update_coins(roll_cost, popup_pos()):
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
		if current_ammo == 0:
			reload(fully_reloadable)
		else:
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
	velocity = direction * speed
	move_and_slide()
	if direction == Vector2.ZERO:
		state = IDLE
		Animator.play("idle")


func roll_pressed() -> void:
	state = ROLL
	velocity = roll_direction * speed * ROLL_MULT
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
	if ReloadTimer.time_left < 0.2 and !ReloadTimer.is_stopped():
		await ReloadTimer.timeout
	elif FullReloadTimer.time_left < 0.2 and !FullReloadTimer.is_stopped():
		await FullReloadTimer.timeout
	Sound.shoot()
	current_ammo -= 1
	AmmoCount.value = current_ammo
	
	var bullet := bullet_scene.instantiate()
	bullet.position = muzzle_pos
	bullet.set_parameters((position - mouse_pos).normalized(), piercing_level)
	BulletManager.add_child(bullet)
	bullet.connect("two_enemies_hit", Callable(self, "_on_two_enemies_hit")) #check if signal has been emitted to update max_ammo
	GunAnimator.play("shoot")


func _on_two_enemies_hit():
	return
	current_ammo += 1
	AmmoCount.value = current_ammo


func reload(full := false) -> void:
	if state == ROLL or reloading:
		return
	reloading = true
	if full:
		full_reload()
	else:
		reload_bullet()


func full_reload() -> void:
	if current_ammo >= max_ammo:
		reloading = false
		return
	
	GunAnimator.play("reload", 0.5)
	Sound.full_reload()
	if state == ROLL or Game.update_coins(max_ammo * reload_cost, popup_pos()) == false:
		reloading = false
		return
	
	current_ammo = max_ammo
	AmmoCount.value = current_ammo
	FullReloadTimer.start()
	await FullReloadTimer.timeout
	reloading = false


func reload_bullet() -> void:
	if current_ammo >= max_ammo or not is_processing():
		reloading = false
		return
	
	GunAnimator.play("reload")
	Sound.reload()
	if state == ROLL or Game.update_coins(reload_cost, popup_pos()) == false:
		reloading = false
		return
	current_ammo += 1
	AmmoCount.value = current_ammo
	
	ReloadTimer.start()
	await ReloadTimer.timeout
	if reloading:
		reload_bullet()


func popup_pos() -> Vector2:
	return global_position + Vector2(randi() % 15 - 6, -25)

func _on_hurtbox_entered(area: Area2D) -> void:
	pass   #could add grace period i-frames or knockback

func resume() -> void:
	resuming = true
	state = IDLE
	set_process(true)
	reload(true)

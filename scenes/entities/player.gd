extends CharacterBody2D

enum {
	IDLE,
	MOVE,
	ROLL,
	DEAD
}

enum {
	READY,
	SHOOT,
	RELOAD
}

enum {
	NORMAL,
	REVERSE,
	BUCKSHOT
}

@export var BulletManager: Node2D
@export var Game: Node2D
@export var AmmoCount: TextureProgressBar
@export var Entities: Node2D

@onready var Animator := $AnimationPlayer
@onready var GunAnimator := $Gun/AnimationPlayer
@onready var Body := $Body
@onready var Arm := $Gun
@onready var Jacket := $Jacket
@onready var Shadow := $Shadow
@onready var Collider := $Shape
@onready var Sound := $Sound
@onready var Hurtbox := $PlayerHurtbox
@onready var HurtboxShape := $PlayerHurtbox/CollisionShape2D
@onready var ReloadTimer := $Gun/Reload
@onready var FullReloadTimer := $Gun/FullReload
@onready var Ouch := $Ouch

@onready var bullet_scene := preload("bullet.tscn")
@onready var coin_scene := preload("res://scenes/entities/coin.tscn")
@onready var dust_scene := preload("res://scenes/entities/roll_dust.tscn")
@onready var popup_scene := preload("res://scenes/ui/popup.tscn")


var roll_multiplier := 3.5
const ROLL_FRICTION := 800
var speed := 100.0
var state := IDLE
var direction := Vector2.ZERO
var mouse_pos: Vector2
var roll_cd: bool = true
var coin_origin := Vector2(0, -18)

var max_ammo := 6
var current_ammo := 6
var reload_cost := -2
var roll_cost := -3
var piercing_level := 2
var coin_throw_count := 5
var big_coin := false
var ability_cost := 5
var reverse_shot := false
var buckshot := 0
var returns := false

# this is fine & whatever
var roll_direction := Vector2.RIGHT
var muzzle_pos := Vector2.ZERO
var fully_reloadable := false
var gun_state := READY


func _ready():
	Hurtbox.area_entered.connect(_on_hurtbox_entered)
	Animator.animation_finished.connect(finished_animation)
	Ouch.animation_finished.connect(hurtbox_on)
	await get_tree().physics_frame
	set_physics_process(true)
	EventBus.player_death.connect(die)


func _physics_process(delta: float) -> void:
	mouse_pos = get_global_mouse_position()
	get_input_direction()
	muzzle_pos = Arm.global_position + (mouse_pos - Arm.global_position).normalized() * 8.5
	
	if Input.is_action_just_pressed("roll") and roll_cd and Game.update_coins(roll_cost, popup_pos()):
		roll_cd = false
		if gun_state == RELOAD:
			gun_state = READY
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
		shoot(reverse_shot)
	elif Input.is_action_just_pressed("reload"):
		if current_ammo == 0:
			reload(fully_reloadable)
		else:
			reload()
	elif Input.is_action_just_pressed("ability"):
		throw_coins()


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
	velocity = roll_direction * speed * roll_multiplier
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
		Animator.play("idle")


func sprite_flip(flip: bool) -> void:
	Body.flip_h = flip
	Arm.flip_h = flip
	if flip:
		Body.position.x = -3.3
	else:
		Body.position.x = 5


func shoot(reverse := false) -> void:
	if current_ammo == 0:
		Sound.empty()
		popup("No ammo!")
		return
	
	if gun_state == SHOOT and not reverse_shot:
		return
	
	gun_state = SHOOT
	if !ReloadTimer.is_stopped() and ReloadTimer.time_left < 0.1:
		await ReloadTimer.timeout
	elif !FullReloadTimer.is_stopped() and FullReloadTimer.time_left < 0.1:
		await FullReloadTimer.timeout
	
	shoot_bullet(NORMAL)
	for i in buckshot:
		shoot_bullet(BUCKSHOT, i + 1)
	if reverse:
		shoot_bullet(REVERSE)
	
	current_ammo -= 1
	AmmoCount.value = current_ammo
	
	await get_tree().create_timer(0.05).timeout
	gun_state = READY


func shoot_bullet(type, n: int = 0) -> void:
	var bullet := bullet_scene.instantiate()
	bullet.position = muzzle_pos
	
	var bullet_direction := (muzzle_pos - mouse_pos).normalized()
	if type == REVERSE:
		bullet_direction *= Vector2(-1, -1)
	
	var piercing := 1 if type == BUCKSHOT else piercing_level
	
	bullet.set_parameters(bullet_direction, piercing, n)
	BulletManager.add_child(bullet)
	
	GunAnimator.play("shoot")
	Sound.shoot(false if type == NORMAL else true)


func throw_coins() -> void:
	if !Game.update_coins(-ability_cost, popup_pos()):
		return
	for i in coin_throw_count:
		var coin := coin_scene.instantiate()
		coin.global_position = global_position + coin_origin
		Entities.add_child(coin)
		coin.set_parameters(mouse_pos, i, returns, big_coin)


func reload(full := false) -> void:
	if state == ROLL or gun_state == RELOAD:
		return
	gun_state = RELOAD
	if full:
		full_reload()
	else:
		reload_bullet()


func full_reload() -> void:
	if current_ammo >= max_ammo:
		gun_state = READY
		return
	
	GunAnimator.play("full_reload")
	Sound.full_reload()
	if state == ROLL:
		gun_state = READY
		return
	if Game.update_coins((max_ammo - current_ammo) * reload_cost * 0.5, popup_pos()) == false:
		reload_bullet()
		return
	
	current_ammo = max_ammo
	AmmoCount.value = current_ammo
	FullReloadTimer.start()
	await FullReloadTimer.timeout
	gun_state = READY


func reload_bullet() -> void:
	if current_ammo >= max_ammo or not is_physics_processing():
		gun_state = READY
		return
	
	GunAnimator.play("reload")
	Sound.reload()
	if state == ROLL or Game.update_coins(reload_cost, popup_pos()) == false:
		gun_state = READY
		return
	current_ammo += 1
	AmmoCount.value = current_ammo
	
	ReloadTimer.start()
	await ReloadTimer.timeout
	if gun_state == RELOAD:
		reload_bullet()


func popup_pos() -> Vector2:
	return global_position + Vector2(RNG.random_int(15) - 6, -25)


func _on_hurtbox_entered(_area: Area2D) -> void:
	HurtboxShape.set_deferred("disabled", true)
	if state == DEAD:
		return
	Ouch.play("ouch")
	$Ouch/Ouchie.play()


func hurtbox_on(_anim_name: String) -> void:
	if state != DEAD:
		HurtboxShape.disabled = false


func speedup(multiplier: float) -> void:
	speed *= multiplier
	Animator.speed_scale *= multiplier


func resume() -> void:
	await get_tree().physics_frame
	state = IDLE
	set_physics_process(true)
	if current_ammo < max_ammo:
		popup("Reloading")
	await get_tree().create_timer(0.1).timeout
	Animator.play("idle")
	await get_tree().create_timer(0.6).timeout
	reload(true)


func popup(message: String) -> void:
	var popup_instance := popup_scene.instantiate()
	Game.add_child(popup_instance)
	popup_instance.global_position = popup_pos()
	popup_instance.pop(message, false)


func die() -> void:
	HurtboxShape.set_deferred("disabled", true)
	if state == DEAD:
		return
	state = DEAD
	Animator.process_mode = Node.PROCESS_MODE_ALWAYS
	set_physics_process(false)
	Animator.play("death")

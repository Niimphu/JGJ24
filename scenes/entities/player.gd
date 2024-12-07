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
@onready var HurtboxShape := $PlayerHurtbox/CollisionShape2D
@onready var ReloadTimer := $Gun/Reload
@onready var FullReloadTimer := $Gun/FullReload
@onready var Ouch := $Ouch

@onready var bullet_scene := preload("bullet.tscn")
@onready var coin_scene := preload("res://scenes/entities/coin.tscn")
@onready var dust_scene := preload("res://scenes/entities/roll_dust.tscn")
@onready var popup_scene := preload("res://scenes/ui/popup.tscn")


const ROLL_MULT := 3.5
const ROLL_FRICTION := 800
var speed := 120.0
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
var ability_coin_count := 4

# this is fine & whatever
var roll_direction := Vector2.RIGHT
var muzzle_pos := Vector2.ZERO
var resuming := false
var fully_reloadable := false


func _ready():
	Hurtbox.area_entered.connect(_on_hurtbox_entered)
	Animator.animation_finished.connect(finished_animation)
	Ouch.animation_finished.connect(hurtbox_on)
	set_process(true)
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


func shoot() -> void:
	if current_ammo == 0:
		Sound.empty()
		popup("No ammo!")
		return
	
	reloading = false
	if !ReloadTimer.is_stopped() and ReloadTimer.time_left < 0.1:
		await ReloadTimer.timeout
	elif !FullReloadTimer.is_stopped() and FullReloadTimer.time_left < 0.1:
		await FullReloadTimer.timeout
	Sound.shoot()
	current_ammo -= 1
	AmmoCount.value = current_ammo
	
	var bullet := bullet_scene.instantiate()
	bullet.position = muzzle_pos
	bullet.set_parameters((muzzle_pos - mouse_pos).normalized(), piercing_level)
	BulletManager.add_child(bullet)
	GunAnimator.play("shoot")


func throw_coins() -> void:
	if !Game.update_coins(-ability_coin_count, popup_pos()):
		print("wa wa")
	



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
	
	GunAnimator.play("full_reload")
	Sound.full_reload()
	if state == ROLL or Game.update_coins((max_ammo - current_ammo) * reload_cost, popup_pos()) == false:
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


func _on_hurtbox_entered(_area: Area2D) -> void:
	HurtboxShape.set_deferred("disabled", true)
	Ouch.play("ouch")


func hurtbox_on(_anim_name: String) -> void:
	HurtboxShape.disabled = false


func speedup(multiplier: float) -> void:
	speed *= multiplier
	Animator.speed_scale *= multiplier


func resume() -> void:
	resuming = true
	state = IDLE
	set_process(true)
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

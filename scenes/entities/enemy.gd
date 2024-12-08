extends CharacterBody2D


var id := 1

@onready var Navigator := $NavigationAgent2D
@onready var HurtBox := $Hurtbox
@onready var Hitbox := $Hitbox
@onready var Sprite := $Body
@onready var Ray := $Ray
@onready var DeathSound := $DeathSound

var hit_count := 0
@export_group("Stats")
## I AM SPEED
@export var speed := 75
## Number enemies this counts as for piercing
@export var armour := 1
## Number of bullets needed to kill this enemy
@export var health := 1
## Number of coins to subtract from player on hit
@export var damage := 5
## Coins to assign to the player on enemy death
@export var value := 1
## Where popups will appear above this guy
@export var height := Vector2(0, -20)
## Flying ignores terrain
@export var flying := false
## You can guess what this does
@export var attack_through_walls := false
@export var knockback_speed := 20
## How close the player should be before attacking
@export var attack_range := 25

@export_group("Nodes")
@export var Animator: AnimationPlayer
@export var Attacker: Node2D
## Anything else that needs flipping for this enemy- make sure origin.x of node is 0
@export var AdditionalFlippers: Array[Node2D]

enum { CHASE, ATTACK, DIE }

var Player: CharacterBody2D
var state := CHASE
var direction := Vector2.ZERO

signal died

func _ready():
	attack_range *= attack_range
	set_physics_process(false)
	await get_tree().physics_frame
	HurtBox.area_entered.connect(_on_hurtbox_entered)
	Hitbox.area_entered.connect(_on_hitbox_entered)
	Animator.animation_finished.connect(finished_animation)
	Navigator.velocity_computed.connect(safe_velocity_computed)
	EventBus.player_death.connect(func(): set_physics_process(false))


func begin(player_node: CharacterBody2D, new_id: int):
	Player = player_node
	id = new_id
	await get_tree().physics_frame
	set_physics_process(true)
	call_deferred("find_path")


func _physics_process(_delta):
	match state:
		CHASE:
			if can_attack():
				attack()
			elif flying:
				fly()
			else:
				chase()
			flip_sprite()
		ATTACK:
			pass
		DIE:
			die()


func chase() -> void:
	direction = to_local(Navigator.get_next_path_position()).normalized()
	var intended_velocity: Vector2 = direction * speed
	
	Navigator.velocity = intended_velocity
	
	if Engine.get_physics_frames() % 5 != id:
		return
	find_path()


func fly() -> void:
	if global_position.distance_squared_to(Player.Hurtbox.global_position) < attack_range * 0.3:
		return
	direction = Player.Hurtbox.global_position - Sprite.global_position
	velocity = direction.normalized() * speed
	move_and_slide()


func can_attack() -> bool:
	Ray.target_position = to_local(Player.global_position) + Vector2(0, 20)
	if Sprite.global_position.distance_squared_to(Player.Hurtbox.global_position) > attack_range:
		return false
	elif attack_through_walls:
		return true
	var collider: Object = Ray.get_collider()
	if collider:
		return false
	return true


func attack() -> void:
	state = ATTACK
	Attacker.attack()


func die() -> void:
	velocity = knockback_speed * direction
	knockback_speed /= 2
	move_and_slide()


func flip_sprite():
	if direction.x > 0:
		for thing in AdditionalFlippers:
			thing.scale.x = 1
		Sprite.flip_h = false
	else:
		for thing in AdditionalFlippers:
			thing.scale.x = -1
		Sprite.flip_h = true


func find_path() -> void:
	Navigator.target_position = Player.global_position


func safe_velocity_computed(safe_velocity: Vector2) -> void:
	if not state == CHASE:
		return
	velocity = safe_velocity.normalized() * speed
	move_and_slide()


func death(killer: Area2D):
	if state == DIE:
		return
	state = DIE
	if killer.name == "Bullet":
		direction = global_position - Player.global_position # set knockback direction
	else:
		direction = global_position - killer.global_position
	HurtBox.set_deferred("monitorable", false)
	HurtBox.set_deferred("monitoring", false)
	EventBus.up_mult.emit()
	EventBus.enemy_died.emit(value * killer.multiplier, global_position + height)
	Animator.play("death")


func hurt_animation():
	Animator.play("hurt")


func finished_animation(anim_name: String) -> void:
	if anim_name == "attack":
		state = CHASE
		Animator.play("chase")
	elif anim_name == "death":
		died.emit()
		queue_free()


func _on_hurtbox_entered(killer: Area2D) -> void:
	health -= 1
	if health <= 0:
		death(killer)
	else:
		Animator.play("hurt")


func _on_hitbox_entered(_area: Area2D) -> void:
	if state != DIE:
		EventBus.player_hit.emit(-damage, global_position + height)

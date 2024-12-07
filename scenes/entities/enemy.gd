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
@export var damage := 10
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

enum { CHASE, ATTACK, DIE }

var Player: CharacterBody2D
var state := CHASE
var direction := Vector2.ZERO

signal died

func _ready():
	attack_range *= attack_range
	set_process(false)
	HurtBox.area_entered.connect(_on_hurtbox_entered)
	Hitbox.area_entered.connect(_on_hitbox_entered)
	Animator.animation_finished.connect(finished_animation)
	Navigator.velocity_computed.connect(safe_velocity_computed)


func begin(player_node: CharacterBody2D, new_id: int):
	Player = player_node
	id = new_id
	set_process(true)
	find_path()


func _physics_process(_delta):
	match state:
		CHASE:
			if Engine.get_physics_frames() % 5 == id and can_attack():
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
	direction = Player.global_position - global_position
	velocity = direction.normalized() * speed
	move_and_slide()


func can_attack() -> bool:
	Ray.target_position = to_local(Player.global_position)
	if global_position.distance_squared_to(Player.global_position) > attack_range:
		return false
	elif attack_through_walls:
		return true
	var collider: Object = Ray.get_collider()
	if !collider or collider is not PhysicsBody2D:
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
		Sprite.flip_h = false
	else:
		Sprite.flip_h = true


func find_path() -> void:
	Navigator.target_position = Player.global_position


func safe_velocity_computed(safe_velocity) -> void:
	if not state == CHASE:
		return
	velocity = velocity.move_toward(safe_velocity, 100)
	move_and_slide()


func death(bullet: Area2D):
	state = DIE
	direction = global_position - Player.global_position # set knockback direction
	HurtBox.set_deferred("monitorable", false)
	HurtBox.set_deferred("monitoring", false)
	
	EventBus.enemy_died.emit(value * bullet.multiplier, global_position + height)
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


func _on_hurtbox_entered(bullet: Area2D) -> void:
	health -= 1
	if health <= 0:
		death(bullet)
	else:
		hurt_animation()


func _on_hitbox_entered(_area: Area2D) -> void:
	if state != DIE:
		EventBus.player_hit.emit(-damage, global_position + height)

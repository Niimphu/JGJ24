extends CharacterBody2D


var id := 1

@onready var Navigator := $NavigationAgent2D
@onready var HurtBox := $Hurtbox
@onready var Hitbox := $Hitbox
@onready var Sprite := $Body

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
@export var knockback_speed := 20

@export_group("Nodes")
@export var Animator: AnimationPlayer

enum { CHASE, ATTACK, DIE }

var Player: CharacterBody2D
var state := CHASE
var direction := Vector2.ZERO

signal died

func _ready():
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
			chase()
			flip_sprite()
		DIE:
			die()


func chase() -> void:
	if flying:
		return fly()
	
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
	if anim_name == "death":
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

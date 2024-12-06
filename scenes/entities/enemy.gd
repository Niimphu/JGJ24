extends CharacterBody2D

@export var speed := 75
var id := 1

@onready var Navigator := $NavigationAgent2D
@onready var HurtBox := $Hurtbox
@onready var Animator := $AnimationPlayer
@onready var Sprite := $Body

var hit_count := 0
## Number enemies this counts as for piercing
@export var armour := 1
## Number of bullets needed to kill this enemy
@export var health := 1

var player: Node2D

signal died

func _ready():
	set_process(false)
	HurtBox.area_entered.connect(_on_area_2d_area_entered)
	Animator.animation_finished.connect(finished_animation)
	Navigator.velocity_computed.connect(safe_velocity_computed)


func begin(player_node: CharacterBody2D, new_id: int):
	player = player_node
	id = new_id
	set_process(true)
	find_path()


func _physics_process(_delta):
	var direction: Vector2 = to_local(Navigator.get_next_path_position()).normalized()
	var intended_velocity: Vector2 = direction * speed
	
	Navigator.velocity = intended_velocity
	
	if velocity.x > 0:
		Sprite.flip_h = false
	else:
		Sprite.flip_h = true
	
	if Engine.get_physics_frames() % 5 != id:
		return
	find_path()


func find_path() -> void:
	Navigator.target_position = player.global_position


func safe_velocity_computed(safe_velocity) -> void:
	velocity = velocity.move_toward(safe_velocity, 100)
	move_and_slide()


func _on_area_2d_area_entered(_area: Area2D) -> void:
	health -= 1
	if health == 0:
		death_animation()


func death_animation():
	speed = 0
	Animator.play("death")


func finished_animation(anim_name: String) -> void:
	if anim_name == "death":
		died.emit()
		EventBus.enemy_died.emit()
		queue_free()

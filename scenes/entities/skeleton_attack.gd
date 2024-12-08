extends Node2D

var attacking := false

@onready var Bow := $Bow
@onready var BowAnimator := $AnimationPlayer
@onready var ArrowOrigin := $Bow/ArrowOrigin

@export var Skeleton: CharacterBody2D
@export var Animator: AnimationPlayer
@onready var arrow_scene := preload("res://scenes/entities/arrow.tscn")
var Player: CharacterBody2D

func _ready():
	BowAnimator.animation_finished.connect(animation_finished)
	await Skeleton.ready
	await get_tree().physics_frame
	Player = Skeleton.Player


func _physics_process(_delta):
	if attacking:
		move_bow()
	else:
		flip_bow()


func move_bow() -> void:
	if !Player:
		return
	Bow.flip_h = false
	Bow.offset.x = 2.2
	Bow.position.x = -2.2
	
	Bow.look_at(Player.Hurtbox.global_position)


func flip_bow() -> void:
	if Skeleton.direction.x > 0:
		Bow.offset.x = 2.2
		Bow.flip_h = false
		Bow.position.x = -2.2
	else:
		Bow.offset.x = -2.2
		Bow.flip_h = true
		Bow.position.x = 2.2



func attack() -> void:
	Animator.play("attack")
	BowAnimator.play("attack")
	attacking = true


func shoot_arrow() -> void:
	var arrow := arrow_scene.instantiate()
	Player.BulletManager.add_child(arrow)
	arrow.set_parameters(Player.Hurtbox.global_position - Bow.global_position)
	arrow.global_position = ArrowOrigin.global_position


func animation_finished(anim_name: String) -> void:
	if anim_name == "attack":
		attacking = false
		Bow.rotation = 0
		BowAnimator.play("chase")
	

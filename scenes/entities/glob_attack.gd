extends Node2D

@onready var Animator := $"../AnimationPlayer"
@onready var glob_scene := preload("res://scenes/entities/glob.tscn")


@export var Globber: CharacterBody2D
@export var AttackAnimator: AnimationPlayer
@onready var arrow_scene := preload("res://scenes/entities/arrow.tscn")

var Player: CharacterBody2D

func _ready():
	await Globber.ready
	await get_tree().physics_frame
	Player = Globber.Player


func attack() -> void:
	Animator.play("attack")


func make_blob() -> void:
	AttackAnimator.play("glob")
	var glob := glob_scene.instantiate()
	Player.Entities.add_child(glob)
	glob.set_parameters(Player)
	glob.global_position = Player.global_position

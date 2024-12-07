extends Node2D

@onready var Animator: AnimationPlayer = $"..".Animator

func attack():
	Animator.play("attack")

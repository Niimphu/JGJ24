extends Control

@onready var Animator := $AnimationPlayer
@onready var Text := $Label


func _ready():
	Animator.animation_finished.connect(destroy)


func pop(amount: int):
	if amount < 0:
		Text.text = str(amount)
		Animator.play("lose")
	else:
		Text.text = "+" + str(amount)
		Animator.play("gain")
	
	var tween := get_tree().create_tween()
	tween.tween_property(self, "position", position + Vector2(1, -8), 1)


func destroy(_anim_name):
	queue_free()

extends Control

@onready var Animator := $AnimationPlayer
@onready var Text := $Label


func _ready():
	Animator.animation_finished.connect(destroy)


func pop(amount: String, gain: bool):
	if gain:
		Text.text = "+" + amount
		Animator.play("gain")
	else:
		Text.text = amount
		Animator.play("lose")
	
	var tween := get_tree().create_tween()
	tween.tween_property(self, "position", position + Vector2(1, -8), 0.7)


func destroy(_anim_name):
	queue_free()

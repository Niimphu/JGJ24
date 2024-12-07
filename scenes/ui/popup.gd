extends Control

@onready var Animator := $AnimationPlayer
@onready var Text := $Label
@onready var Kaching := $Kaching


func _ready():
	Animator.animation_finished.connect(destroy)


func pop(amount: String, gain: bool):
	if gain:
		Kaching.pitch_scale += clamp((int(amount) - 1) * 0.025, 0, 1.5)
		Text.text = "+" + amount
		Animator.play("gain")
	else:
		Text.text = amount
		Animator.play("lose")


func destroy(_anim_name):
	queue_free()

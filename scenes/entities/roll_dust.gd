extends AnimatedSprite2D

func _ready():
	animation_finished.connect(kms)

func kms() -> void:
	queue_free()

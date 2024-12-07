extends Area2D

func _ready():
	area_entered.connect(be_shot)


func be_shot():
	queue_free()

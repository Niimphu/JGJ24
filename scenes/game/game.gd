extends Node2D

@export var CoinCount: Control

@onready var popup_scene := preload("res://scenes/ui/popup.tscn")

var coins := 36

func _ready():
	CoinCount.text = str(coins)


func update_coins(amount: int, location: Vector2) -> bool:
	if coins + amount < 0:
		return false
	coins += amount
	CoinCount.text = str(coins)
	popup(amount, location)
	return true


func popup(amount: int, location: Vector2) -> void:
	print(amount, " ", location)
	var popup_instance := popup_scene.instantiate()
	add_child(popup_instance)
	popup_instance.global_position = location
	popup_instance.pop(amount)
	

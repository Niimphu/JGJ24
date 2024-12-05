extends Node2D

@export var WaveManager: Node2D
@export var CoinCount: Control

@onready var popup_scene := preload("res://scenes/ui/popup.tscn")

var coins := 36
var current_wave := 0

func _ready():
	CoinCount.text = str(coins)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	spawn_next_wave()


func spawn_next_wave():
	await get_tree().create_timer(3).timeout
	WaveManager.spawn_wave(current_wave)



func update_coins(amount: int, location: Vector2) -> bool:
	if coins + amount < 0:
		return false
	coins += amount
	CoinCount.text = str(coins)
	popup(amount, location)
	return true


func popup(amount: int, location: Vector2) -> void:
	var popup_instance := popup_scene.instantiate()
	add_child(popup_instance)
	popup_instance.global_position = location
	popup_instance.pop(amount)
	

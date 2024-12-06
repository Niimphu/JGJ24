extends Node2D

@export var WaveManager: Node2D
@export var CoinCount: Control

@onready var popup_scene := preload("res://scenes/ui/popup.tscn")

@onready var final_wave: int = WaveManager.waves.size()

var coins := 36
var current_wave := 0
var current_wave_enemy_count := 0
var wave_spawning := false


func _ready():
	CoinCount.text = str(coins)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	WaveManager.wave_complete.connect(wave_complete)
	spawn_next_wave()


func spawn_next_wave():
	current_wave_enemy_count = 0
	wave_spawning = true
	await get_tree().create_timer(3).timeout
	WaveManager.spawn_wave(current_wave)


func wave_complete() -> void:
	current_wave += 1
	if current_wave == final_wave:
		print("final wave done")
	else: #temp: change to shop logic
		await get_tree().create_timer(3).timeout
		spawn_next_wave()
	print("finito")


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
	

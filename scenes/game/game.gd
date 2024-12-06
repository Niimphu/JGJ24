extends Node2D

@export var WaveManager: Node2D
@export var UpgradeManager: Node2D
@export var CoinCount: Label
@export var UpgradeMenu: Control
@export var Player: CharacterBody2D
@export var Crosshair: Node2D

@onready var popup_scene := preload("res://scenes/ui/popup.tscn")

@onready var final_wave: int = WaveManager.waves.size()
##Change for starting coin value
@export var coins := 50
var current_wave := 0
var current_wave_enemy_count := 0
var wave_spawning := false
var add_coin := false


func _ready():
	CoinCount.text = str(coins)
	EventBus.enemy_died.connect(_on_enemy_died)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	UpgradeManager.upgrade_selected.connect(spawn_next_wave)
	WaveManager.wave_complete.connect(wave_complete)
	UpgradeMenu.visible = false
	spawn_next_wave()


func spawn_next_wave():
	resume()
	UpgradeMenu.visible = false
	current_wave_enemy_count = 0
	wave_spawning = true
	await get_tree().create_timer(2).timeout
	WaveManager.spawn_wave(current_wave)


func wave_complete() -> void:
	current_wave += 1
	if current_wave == final_wave:
		# ggs
		pass
	else:
		await get_tree().create_timer(0.5).timeout
		UpgradeMenu.visible = true
		pause()


func update_coins(amount: int, location: Vector2) -> bool:
	if coins + amount < 0:
		return false #emit death signal
	coins += amount
	CoinCount.text = str(coins)
	popup(amount, location)
	return true


func popup(amount: int, location: Vector2) -> void:
	var popup_instance := popup_scene.instantiate()
	add_child(popup_instance)
	popup_instance.global_position = location
	popup_instance.pop(amount)


func pause() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	Player.set_process(false)


func resume() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Player.resume()
	
func _on_enemy_died(amount: int, location: Vector2): #works but does not visually affect counter until roll used
	update_coins(amount, location)

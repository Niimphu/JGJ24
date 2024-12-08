extends Node2D

@export var WaveManager: Node2D
@export var UpgradeManager: Node2D
@export var CoinCount: Label
@export var UpgradeMenu: Control
@export var Player: CharacterBody2D
@export var Crosshair: Node2D
@export var GGAnimator: AnimationPlayer
@export var GGLabel: Label

@onready var popup_scene := preload("res://scenes/ui/popup.tscn")

@onready var final_wave: int = WaveManager.waves.size()
@onready var Music := $Music
##Change for starting coin value
@export var coins := 10
var current_wave := 0
var current_wave_enemy_count := 0
var wave_spawning := false
var add_coin := false
var await_restart := false


func _ready():
	CoinCount.text = str(coins)
	
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.explosion_money.connect(gain_explosion_money)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	UpgradeManager.upgrade_selected.connect(spawn_next_wave)
	WaveManager.wave_complete.connect(wave_complete)
	
	UpgradeMenu.undisplay()
	UpgradeMenu.visible = false
	WaveManager.spawn_wave(current_wave)
	wave_spawning = true
	AudioServer.get_bus_effect(1, 2).volume_db = 0
	AudioServer.set_bus_effect_enabled(1, 0, false)
	AudioServer.set_bus_effect_enabled(1, 1, false)


func _process(_delta):
	if await_restart and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()


func spawn_next_wave():
	resume()
	UpgradeMenu.visible = false
	current_wave_enemy_count = 0
	wave_spawning = true
	WaveManager.spawn_wave(current_wave)


func wave_complete() -> void:
	current_wave += 1
	if current_wave == final_wave:
		game_over(true)
	else:
		await get_tree().create_timer(1).timeout
		pause()
		UpgradeMenu.display()


func update_coins(amount: int, location: Vector2, is_damage: bool = false) -> bool:
	if coins + amount < 0 and not is_damage:
		popup(0, location)
		return false
	coins += amount
	CoinCount.text = str(coins)
	popup(amount, location)
	if coins < 0:
		EventBus.player_death.emit()
		AudioServer.set_bus_effect_enabled(1, 0, true)
		AudioServer.set_bus_effect_enabled(1, 1, true)
		var tween := get_tree().create_tween()
		tween.tween_property(Music, "volume_db", -100, 2)
		game_over()
	return true


func game_over(victory := false) -> void:
	await get_tree().create_timer(2).timeout
	var tween := get_tree().create_tween()
	tween.tween_property(AudioServer.get_bus_effect(1, 2), "volume_db", -25, 2)
	if victory:
		GGLabel.text = "Victory!"
	GGAnimator.play("fade")
	await GGAnimator.animation_finished
	Player.set_physics_process(false)
	await_restart = true


func popup(amount: int, location: Vector2) -> void:
	var popup_instance := popup_scene.instantiate()
	if get_tree().paused:
		UpgradeMenu.add_child(popup_instance)
		popup_instance.global_position = UpgradeMenu.get_local_mouse_position()
	else:
		add_child(popup_instance)
		popup_instance.global_position = location
	popup_instance.pop("Can't afford!" if amount == 0 else str(amount), amount > 0)


func pause() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	Player.gun_state = Player.READY
	Player.set_physics_process(false)


func resume() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Player.resume()


func _on_enemy_died(amount: int, location: Vector2): #works but does not visually affect counter until roll used
	update_coins(amount, location)


func _on_player_hit(damage: int, location: Vector2):
	update_coins(damage, location, true)
	

func gain_explosion_money(location: Vector2) -> void:
	update_coins(3, location)

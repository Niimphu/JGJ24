extends Node2D

@onready var Shoot := $Shoot
@onready var shoot_pitch: float = Shoot.pitch_scale
@onready var shoot_volume: float = Shoot.volume_db
@onready var Empty := $Empty
@onready var empty_pitch: float = Empty.pitch_scale
@onready var Reload := $Reload
@onready var reload_pitch: float = Reload.pitch_scale
@onready var FullReload := $FullReload



func shoot(extra := false) -> void:
	if extra:
		await get_tree().create_timer(RNG.random_weight() / 15 + 0.01).timeout
		Shoot.volume_db = shoot_volume - 3
	Shoot.pitch_scale = shoot_pitch + RNG.random_weight() / 5 - 0.1
	Shoot.play()


func empty() -> void:
	Empty.pitch_scale = empty_pitch + RNG.random_weight() / 5 - 0.1
	Empty.play()


func reload() -> void:
	Reload.pitch_scale = reload_pitch + RNG.random_weight() / 5 - 0.1
	Reload.play()


func full_reload() -> void:
	FullReload.play()

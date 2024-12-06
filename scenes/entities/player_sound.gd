extends Node2D

@onready var Shoot := $Shoot
@onready var shoot_pitch: float = Shoot.pitch_scale
@onready var Empty := $Empty
@onready var empty_pitch: float = Empty.pitch_scale
@onready var Reload := $Reload
@onready var reload_pitch: float = Reload.pitch_scale
@onready var FullReload := $FullReload



func shoot() -> void:
	Shoot.pitch_scale = shoot_pitch + randf() / 5 - 0.1
	Shoot.play()


func empty() -> void:
	Empty.pitch_scale = empty_pitch + randf() / 5 - 0.1
	Empty.play()


func reload() -> void:
	Reload.pitch_scale = reload_pitch + randf() / 5 - 0.1
	Reload.play()


func full_reload() -> void:
	FullReload.play()

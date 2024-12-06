extends Node2D

@export var Upgrade1: Button
@export var Upgrade2: Button
@export var Player: CharacterBody2D

signal upgrade_selected

func _ready():
	Upgrade1.button_down.connect(option_1)
	Upgrade2.button_down.connect(option_2)


func select_upgrade(option: int) -> void:
	upgrade_selected.emit()


func option_1():
	select_upgrade(1)


func option_2():
	select_upgrade(2)

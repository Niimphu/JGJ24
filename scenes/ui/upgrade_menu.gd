extends Control

@export var UpgradeManager: Node2D

@onready var Button1 := $MarginContainer/HBoxContainer/Upgrade/Button
@onready var Button2 := $MarginContainer/HBoxContainer/GetMoney/Button


func undisplay():
	hide()
	Button1.disabled = true
	Button2.disabled = true

func display():
	UpgradeManager.new_upgrades()
	show()
	await get_tree().create_timer(0.2).timeout
	Button1.disabled = false
	Button2.disabled = false
	

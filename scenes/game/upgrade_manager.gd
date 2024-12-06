extends Node2D

@export var Upgrade1: Button
@export var Upgrade2: Button
@export var Player: CharacterBody2D

var upgrades := [
	{
		"title": "Pointier bullets",
		"description": "+1 bullet piercing",
		"cost": -15,
		"action": Callable(self, "pointer_bullets"),
		"amount": 3, # number of times this upgrade can be bought
		"inflation": -5 # price increase for subsequent purchases
	},
	{
		"title": "Speeding fine",
		"description": "x1.2 movespeed, +2 roll cost",
		"cost": -20,
		"action": Callable(self, "speeding"),
		"amount": 1
	}
]

var freebies := [
	{
		"title": "Payday",
		"description": "",
		"action": Callable(self, "payday"),
		"cost_string": "+25"
	},
	{
		"title": "Interesting",
		"description": "",
		"action": Callable(self, "interesting"),
		"cost_string": "+10%"
	}
]

var current_upgrade: Dictionary
var current_freebie: Dictionary

signal upgrade_selected

func _ready():
	Upgrade1.button_down.connect(option_1)
	Upgrade2.button_down.connect(option_2)
	new_upgrades()


func new_upgrades() -> void:
	current_upgrade = upgrades[randi() % upgrades.size()]
	Upgrade1.text = current_upgrade["title"] + "\n" + current_upgrade["description"] + "\n" + str(current_upgrade["cost"]) + " coins"
	
	current_freebie = freebies[randi() % freebies.size()]
	Upgrade2.text = current_freebie["title"] + "\n" + current_freebie["description"] + "\n" + current_freebie["cost_string"] + " coins"


func apply_upgrade():
	var upgrade_action = current_upgrade["action"]
	if !upgrade_action.is_valid():
		return
	upgrade_action.call()
	current_upgrade["amount"] -= 1
	if current_upgrade["amount"] <= 0:
		upgrades.erase(current_upgrade)
	else:
		current_upgrade["cost"] += current_upgrade["inflation"]
	visible = false
	new_upgrades()


func apply_freebie():
	var freebie = current_freebie["action"]
	if !freebie.is_valid():
		return
	freebie.call()
	visible = false
	new_upgrades()


func option_1():
	apply_upgrade()
	upgrade_selected.emit()


func option_2():
	apply_freebie()
	upgrade_selected.emit()


func pointer_bullets():
	print("pointy")


func speeding():
	print("sppeed")


func payday():
	print("pay")


func interesting():
	print("inch resting")

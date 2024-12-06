extends Node2D

@export var Upgrade1: Button
@export var Upgrade2: Button
@export var Game: Node2D
@export var Player: CharacterBody2D
@export var UpgradeMenuFader: AnimationPlayer

@onready var NoSound := $No

var upgrades := [
	{
		"title": "Pointier Bullets",
		"description": "+1 bullet piercing",
		"cost": -15,
		"action": Callable(self, "pointer_bullets"),
		"amount": 3, # number of times this upgrade can be bought
		"inflation": -5 # price increase for subsequent purchases
	},
	{
		"title": "Speeding Fine",
		"description": "+30% movespeed, +2 roll cost",
		"cost": -20,
		"action": Callable(self, "speeding"),
		"amount": 2,
		"inflation": -10
	},
	{
		"title": "Disposable Cylinders",
		"description": "-1 max ammo\nreloading from empty fully reloads ammo and is 20% faster",
		"cost": -25,
		"action": Callable(self, "disposable_cylinders"),
		"amount": 1,
	}
]

var freebies := [
	{
		"title": "Payday",
		"description": "",
		"action": Callable(self, "payday"),
		"cost_string": "+20"
	},
	{
		"title": "Interesting",
		"description": "",
		"action": Callable(self, "interesting"),
		"cost_string": "+20%"
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
	Upgrade1.text = current_upgrade["title"] + "\n\n" + current_upgrade["description"] + "\n\n" + str(current_upgrade["cost"]) + " coins"
	
	current_freebie = freebies[randi() % freebies.size()]
	Upgrade2.text = current_freebie["title"] + "\n\n" + current_freebie["description"] + "\n\n" + current_freebie["cost_string"] + " coins"


func apply_upgrade() -> bool:
	var upgrade_action = current_upgrade["action"]
	if !upgrade_action.is_valid():
		return false
	if !Game.update_coins(current_upgrade["cost"], popup_pos()):
		NoSound.play()
		return false
	upgrade_action.call()
	current_upgrade["amount"] -= 1
	if current_upgrade["amount"] <= 0:
		upgrades.erase(current_upgrade)
	else:
		current_upgrade["cost"] += current_upgrade["inflation"]
	
	UpgradeMenuFader.play("fade")
	return true


func apply_freebie():
	var freebie = current_freebie["action"]
	if !freebie.is_valid():
		return
	freebie.call()
	UpgradeMenuFader.play("fade")


func option_1():
	if apply_upgrade():
		await get_tree().create_timer(1).timeout
		upgrade_selected.emit()


func option_2():
	apply_freebie()
	await get_tree().create_timer(1).timeout
	upgrade_selected.emit()


func can_afford(coin_balance: int):
	return coin_balance > current_upgrade["cost"]


func pointer_bullets():
	Player.piercing_level += 1


func speeding():
	Player.speed *= 1.3
	Player.roll_cost -= 2


func payday():
	Game.update_coins(int(current_freebie["cost_string"]), popup_pos())


func interesting():
	Game.update_coins(ceil(float(Game.coins) * 0.2), popup_pos())


func disposable_cylinders():
	Player.max_ammo -= 1
	Player.fully_reloadable = true


func popup_pos() -> Vector2:
	return get_global_mouse_position() + Vector2(-10, -6)

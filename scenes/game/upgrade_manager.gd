extends Node2D

@export var Upgrade: Button
@export var Freebie: Button
@export var Game: Node2D
@export var Player: CharacterBody2D
@export var UpgradeMenuFader: AnimationPlayer

@onready var NoSound := $No

var inflation := 0
var pay_raise := 0

var upgrades := [
	{
		"title": "Two Birds...",
		"description": "+1 bullet piercing",
		"cost": -8,
		"action": Callable(self, "two_birds"),
		"amount": 3 # number of times this upgrade can be bought
	},
	{
		"title": "Speeding Fine",
		"description": "+30% movespeed\n rolls are 2 coins more expensive",
		"cost": -12,
		"action": Callable(self, "speeding"),
		"amount": 2
	},
	{
		"title": "Disposable Cylinders",
		"description": "-1 max ammo\nreloading from empty fully reloads ammo and is 50% cheaper",
		"cost": -15,
		"action": Callable(self, "disposable_cylinders"),
		"amount": 1,
	},
	{
		"title": "Double-Ended Bullets",
		"description": "fire an additional shot backwards\n backwards bullet does not consume ammo",
		"cost": -6,
		"action": Callable(self, "double_ended_bullets"),
		"amount": 1,
	},
	{
		"title": "Buckshot",
		"description": "fire additional shots in a cone\n non-piercing\n extra bullets not consume ammo",
		"cost": -11,
		"action": Callable(self, "buckshot"),
		"amount": 2
	},
	{
		"title": "Spring-Loaded",
		"description": "+50% roll distance",
		"cost": -6,
		"action": Callable(self, "spring_loaded"),
		"amount": 1,
	},
	{
		"title": "Pinching Pennies",
		"description": "+3 coins if coin shower kills at least 1 enemy",
		"cost": -15,
		"action": Callable(self, "scraping_pennies"),
		"amount": 1,
	},
	{
		"title": "BIG Money",
		"description": "coin shower now throws one coin\n +100% explosion size",
		"cost": -14,
		"action": Callable(self, "big_money"),
		"amount": 1,
	}
]

var freebies := [
	{
		"title": "Payday",
		"description": "",
		"action": Callable(self, "payday"),
		"cost": +5,
		"cost_string": ""
	},
	{
		"title": "Interesting",
		"description": "",
		"action": Callable(self, "interesting"),
		"cost": 0,
		"cost_string": "+50%"
	}
]

var current_upgrade: Dictionary
var current_freebie: Dictionary

signal upgrade_selected

func _ready():
	Upgrade.button_down.connect(option_1)
	Freebie.button_down.connect(option_2)
	new_upgrades()


func new_upgrades() -> void:
	current_upgrade = upgrades[RNG.random_int(upgrades.size())]
	Upgrade.text = current_upgrade["title"] + "\n\n" + current_upgrade["description"] + "\n\n" + "Costs " + str(current_upgrade["cost"] + inflation) + " coins"
	
	if Game.current_wave < 3:
		current_freebie = freebies[0]
	else:
		current_freebie = freebies[RNG.random_int(freebies.size())]
	if current_freebie == freebies[0]:
		Freebie.text = current_freebie["title"] + "\n\n" + current_freebie["description"] + "\n\n" + "Gain " + str(current_freebie["cost"] + pay_raise) + " coins"
	else:
		Freebie.text = current_freebie["title"] + "\n\n" + current_freebie["description"] + "\n\n" + "Gain " + current_freebie["cost_string"] + " coins"


func apply_upgrade() -> bool:
	var upgrade_action = current_upgrade["action"]
	if !upgrade_action.is_valid():
		return false
	if !Game.update_coins(current_upgrade["cost"] + inflation, popup_pos()):
		NoSound.play()
		return false
	upgrade_action.call()
	current_upgrade["amount"] -= 1
	if current_upgrade["amount"] <= 0:
		upgrades.erase(current_upgrade)
	
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
		inflation -= 2


func option_2():
	apply_freebie()
	await get_tree().create_timer(1).timeout
	upgrade_selected.emit()


func can_afford(coin_balance: int):
	return coin_balance > current_upgrade["cost"]


func two_birds():
	Player.piercing_level += 1


func speeding():
	Player.speedup(1.3)
	Player.roll_cost -= 2


func payday():
	Game.update_coins(current_freebie["cost"] + pay_raise, popup_pos())
	pay_raise += 2


func interesting():
	Game.update_coins(ceil(float(Game.coins) * 0.5), popup_pos())


func disposable_cylinders():
	Player.max_ammo -= 1
	Player.fully_reloadable = true


func double_ended_bullets():
	Player.reverse_shot = true


func buckshot():
	Player.buckshot += 2


func spring_loaded():
	Player.roll_multiplier = 6


func scraping_pennies():
	Player.returns = true


func big_money():
	Player.big_coin = true
	Player.coin_throw_count = 1


func popup_pos() -> Vector2:
	return get_global_mouse_position() + Vector2(-10, -6)

extends Node2D

@export var EnemiesFolder: Node2D
@export var Player: Node2D

@onready var Bat := preload("res://scenes/entities/eye_bat.tscn")
@onready var Imp := preload("res://scenes/entities/imp_inherited.tscn")


@onready var spawn_points := get_children().map(func(point: Node2D): return point.global_position)

@onready var waves = [
	[ # Wave 1
		{ "type": Imp, "count": 2 },
		{ "type": Bat, "count": 3 },
		{ "type": Bat, "count": 4 }
	],
	[ # Wave 2
		{ "type": Bat, "count": 3 },
		{ "type": Bat, "count": 5 },
		{ "type": Bat, "count": 7 }
		#{ "type": Bat, "count": 2, "type2": EnemyC, "count2": 1 }
	],
	[ # Wave 3
		{ "type": Bat, "count": 5 },
		{ "type": Bat, "count": 5 },
		{ "type": Bat, "count": 5 },
		{ "type": Bat, "count": 5 },
		{ "type": Bat, "count": 5 }
	]
]

var enemies_spawned := 0
var enemies_killed := 0
var burst_delay := 4 # time between bursts during wave
var spawning := true

signal wave_complete


func spawn_wave(wave_number: int):
	enemies_spawned = 0
	enemies_killed = 0
	spawning = true
	for burst in waves[wave_number]:
		spawn_burst(burst)
		await get_tree().create_timer(burst_delay).timeout
	
	spawning = false


func spawn_burst(burst: Dictionary):
	var valid_spawns := get_furthest_points(10)
	
	for i in range(burst["count"]):
		spawn_enemy(burst["type"], valid_spawns)
		await get_tree().create_timer(0.15).timeout
		
	if burst.has("type2"):
		for i in range(burst["count2"]):
			spawn_enemy(burst["type2"], valid_spawns)
			await get_tree().create_timer(0.15).timeout


func spawn_enemy(enemy: PackedScene, valid_spawns: Array) -> void:
	var new_enemy = enemy.instantiate()
	var spawn_point := randi() % valid_spawns.size()
	EnemiesFolder.add_child(new_enemy)
	new_enemy.global_position = valid_spawns[spawn_point]
	valid_spawns.erase(spawn_point)
	new_enemy.begin(Player, enemies_spawned % 5)
	enemies_spawned += 1
	new_enemy.died.connect(enemy_killed)


func enemy_killed() -> void:
	enemies_killed += 1
	if spawning:
		return
	if enemies_killed >= enemies_spawned:
		wave_complete.emit()


func get_furthest_points(num_points: int) -> Array:
	var distances := []
	for point in spawn_points:
		var distance := Player.global_position.distance_to(point)
		distances.append({"point": point, "distance": distance})
	
	distances.sort_custom(func(a, b): return b["distance"] < a["distance"])
	var furthest_points = []
	for i in range(min(num_points, distances.size())):
		furthest_points.append(distances[i]["point"])
	
	return furthest_points

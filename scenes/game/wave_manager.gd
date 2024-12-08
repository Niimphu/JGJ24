extends Node2D

@export var EnemiesFolder: Node2D
@export var Player: Node2D

@onready var Bat := preload("res://scenes/entities/eye_bat.tscn")
@onready var Imp := preload("res://scenes/entities/impling.tscn")
@onready var Skeleton := preload("res://scenes/entities/skeleton.tscn")
@onready var Globber := preload("res://scenes/entities/globber.tscn")


@onready var spawn_points := get_children().map(func(point: Node2D): return point.global_position)

@onready var waves = [
	[ # Wave 1
		{ "type": Bat, "count": 3 },
		{ "type": Bat, "count": 4 },
		{ "type": Bat, "count": 5 },
		{ "type": Bat, "count": 6 },
	],
	[ # 2
		{ "type": Skeleton, "count": 2 },
		{ "type": Skeleton, "count": 2 },
		{ "type": Skeleton, "count": 3 },
		{ "type": Skeleton, "count": 3 },
		{ "type": Skeleton, "count": 2 }
	],
	[ # 3
		{ "type": Bat, "count": 1 },
		{ "type": Bat, "count": 2, "type2": Skeleton, "count2": 1 },
		{ "type": Skeleton, "count": 3 },
		{ "type": Bat, "count": 2, "type2": Skeleton, "count2": 2 },
		{ "type": Bat, "count": 2 },
		{ "type": Bat, "count": 3, "type2": Skeleton, "count2": 2 },
		{ "type": Imp, "count": 2 }
	],
	[ # 4
		{ "type": Bat, "count": 2 },
		{ "type": Imp, "count": 2 },
		{ "type": Bat, "count": 2 },
		{ "type": Imp, "count": 3 },
		{ "type": Imp, "count": 3, "type2": Bat, "count2": 1 },
		{ "type": Imp, "count": 4 },
		{ "type": Imp, "count": 2 }
	],
	[ # 5
		{ "type": Imp, "count": 5 },
		{ "type": Imp, "count": 2, "type2": Skeleton, "count2": 2  },
		{ "type": Skeleton, "count": 3 },
		{ "type": Imp, "count": 3 },
		{ "type": Imp, "count": 5, "type2": Skeleton, "count2": 2 },
		{ "type": Imp, "count": 2, "type2": Skeleton, "count2": 3 }
	],
	[ # 6
		{ "type": Bat, "count": 5, "type2": Imp, "count2": 3 },
		{ "type": Skeleton, "count": 2 },
		{ "type": Bat, "count": 4 },
		{ "type": Imp, "count": 2, "type2": Skeleton, "count2": 2 },
		{ "type": Bat, "count": 5, "type2": Skeleton, "count2":2 },
		{ "type": Imp, "count": 4 }
	],
	[ # 7
		{ "type": Imp, "count": 4, "type2": Skeleton, "count2": 1 },
		{ "type": Imp, "count": 3, "type2": Skeleton, "count2": 2 },
		{ "type": Imp, "count": 2, "type2": Skeleton, "count2": 3 },
		{ "type": Imp, "count": 1, "type2": Skeleton, "count2": 4 },
		{ "type": Imp, "count": 3, "type2": Skeleton, "count2": 3 },
		{ "type": Globber, "count": 1 }
	],
	[ # 8
		{ "type": Bat, "count": 4, "type2": Imp, "count2": 3 },
		{ "type": Bat, "count": 4, "type2": Skeleton, "count2": 2, "type3": Globber, "count3": 1 },
		{ "type": Imp, "count": 2, "type2": Skeleton, "count2": 2 },
		{ "type": Bat, "count": 5 },
		{ "type": Imp, "count": 3, "type2": Skeleton, "count2": 2, "type3": Globber, "count3": 2 },
	],
	[ # 9
		{ "type": Bat, "count": 1, "type2": Imp, "count2": 1, "type3": Skeleton, "count3": 1 },
		{ "type": Globber, "count": 2 },
		{ "type": Bat, "count": 2, "type2": Imp, "count2": 2, "type3": Skeleton, "count3": 2 },
		{ "type": Bat, "count": 3 , "type2": Imp, "count2": 2},
		{ "type": Globber, "count": 2 },
		{ "type": Imp, "count": 3, "type2": Skeleton, "count2": 2 },
		{ "type": Imp, "count": 3, "type2": Skeleton, "count2": 2 },
		{ "type": Globber, "count": 2 },
		{ "type": Bat, "count": 3, "type2": Imp, "count2": 3, "type3": Skeleton, "count3": 3},
		{ "type": Globber, "count": 2 },
	]
]

var enemies_spawned := 0
var enemies_killed := 0
var burst_delay := 5 # time between bursts during wave
var spawning := true

signal wave_complete


func spawn_wave(wave_number: int):
	enemies_spawned = 0
	enemies_killed = 0
	spawning = true
	for burst in waves[wave_number]:
		await get_tree().create_timer(burst_delay).timeout
		spawn_burst(burst)
	spawning = false


func spawn_burst(burst: Dictionary):
	var valid_spawns := get_furthest_points(13)
	
	for i in range(burst["count"]):
		spawn_enemy(burst["type"], valid_spawns)
		await get_tree().create_timer(0.15).timeout
		
	if burst.has("type2"):
		for i in range(burst["count2"]):
			spawn_enemy(burst["type2"], valid_spawns)
			await get_tree().create_timer(0.15).timeout
	else:
		return
	
	if burst.has("type3"):
		for i in range(burst["count3"]):
			spawn_enemy(burst["type3"], valid_spawns)
			await get_tree().create_timer(0.15).timeout
	else:
		return
	
	if burst.has("type4"):
		for i in range(burst["count4"]):
			spawn_enemy(burst["type4"], valid_spawns)
			await get_tree().create_timer(0.15).timeout
	else:
		return


func spawn_enemy(enemy: PackedScene, valid_spawns: Array) -> void:
	var new_enemy = enemy.instantiate()
	var spawn_point := RNG.random_int(valid_spawns.size())
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

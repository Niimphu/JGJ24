extends Node2D

@export var EnemiesFolder: Node2D
@export var Player: Node2D

@onready var test_enemy := preload("res://scenes/entities/test_enemy.tscn")
@onready var spawn_points := get_children().map(func(point: Node2D): return point.global_position)

@onready var waves = [
	[ # Wave 1
		{ "type": test_enemy, "count": 3 },
		{ "type": test_enemy, "count": 5 }
	#],
	#[ # Wave 2
		#{ "type": EnemyB, "count": 5 },
		#{ "type": EnemyC, "count": 2 },
		#{ "type": EnemyB, "count": 2, "type2": EnemyC, "count2": 1 }
	]
]

var burst_delay := 5 # time between bursts during wave


func spawn_wave(wave_number: int):
	for burst in waves[wave_number]:
		spawn_burst(burst)
		await get_tree().create_timer(burst_delay).timeout


func spawn_burst(burst: Dictionary):
	var valid_spawns := get_furthest_points(10)
	
	for i in range(burst["count"]):
		var enemy = burst["type"].instantiate()
		# Add the enemy to the scene at some spawn location
		add_child(enemy)
		enemy.global_position = valid_spawns[randi() % 6]
		enemy.begin(Player)
		await get_tree().create_timer(0.15).timeout
	
	if burst.has("type2"):
		for i in range(burst["count2"]):
			var enemy = burst["type2"].instance()
			add_child(enemy)
			enemy.global_position = valid_spawns[randi() % 6]
			enemy.begin(Player)
			await get_tree().create_timer(0.15).timeout


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

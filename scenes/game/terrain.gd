extends TileMapLayer

@onready var candlelight_scene := preload("res://scenes/game/candle_light.tscn")


func _ready():
	var candle_locations: Array
	for tile in get_used_cells():
		if get_cell_atlas_coords(tile) == Vector2i(9, 1) or get_cell_atlas_coords(tile) == Vector2i(11, 1) or get_cell_atlas_coords(tile) == Vector2i(13, 1):
			spawn_candlelight(map_to_local(tile))

func spawn_candlelight(location: Vector2i) -> void:
	var candlelight := candlelight_scene.instantiate()
	add_child(candlelight)
	candlelight.global_position = Vector2(location)

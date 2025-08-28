extends Node2D
class_name TDMap2

@export var land: TileMap
@export var walking_line: TileMap
@export var rock: TileMap
@export var water: TileMap
@export var water_deep: TileMap

# แปลง world position → cell
func world_to_cell(pos: Vector2) -> Vector2i:
	return land.local_to_map(to_local(pos))

# แปลง cell → world position (กึ่งกลางช่อง)
func cell_to_world(cell: Vector2i) -> Vector2:
	return land.map_to_local(cell) + Vector2(land.tile_set.tile_size) * 0.5

# เช็กว่ามี tile อยู่ใน TileMap นั้นรึเปล่า
func _has_tile(tmap: TileMap, cell: Vector2i) -> bool:
	return tmap and tmap.get_cell_source_id(0, cell) != -1

# เช็กว่าวางป้อมได้มั้ย
func is_buildable(cell: Vector2i) -> bool:
	var on_land  := _has_tile(land, cell)
	var on_path  := _has_tile(walking_line, cell)
	var on_rock  := _has_tile(rock, cell)
	var on_water := _has_tile(water, cell)
	var on_deep  := _has_tile(water_deep, cell)
	return on_land and not (on_path or on_rock or on_water or on_deep)

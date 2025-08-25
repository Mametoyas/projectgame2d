extends Node2D
# ไม่ใส่ class_name เพื่อเลี่ยงชนกันกับสคริปต์แมพอื่น ๆ

@export var land: TileMap
@export var walking_line: TileMap
@export var rock: TileMap
@export var water: TileMap
@export var water_deep: TileMap

# หลายเส้นทางในแมพนี้ (ลาก Forest2Line1/2/3 มาใส่ หรือปล่อยว่างให้ระบบหาเองก็ได้)
@export var paths: Array[Path2D] = []

func _ready() -> void:
	# ถ้ายังไม่ตั้ง paths ใน Inspector ฟ้าจะค้นหา Path2D ใต้ walking_line ให้อัตโนมัติ
	if paths.is_empty() and walking_line:
		for c in walking_line.get_children():
			if c is Path2D:
				paths.append(c)

# ---------- Utilities สำหรับกริดวางป้อม ----------
func world_to_cell(pos: Vector2) -> Vector2i:
	return land.local_to_map(to_local(pos))

func cell_to_world(cell: Vector2i) -> Vector2:
	return land.map_to_local(cell) + Vector2(land.tile_set.tile_size) * 0.5

func _has_tile(tmap: TileMap, cell: Vector2i) -> bool:
	return tmap and tmap.get_cell_source_id(0, cell) != -1

func is_buildable(cell: Vector2i) -> bool:
	var on_land  := _has_tile(land, cell)
	var on_path  := _has_tile(walking_line, cell)
	var on_rock  := _has_tile(rock, cell)
	var on_water := _has_tile(water, cell)
	var on_deep  := _has_tile(water_deep, cell)
	return on_land and not (on_path or on_rock or on_water or on_deep)

# ---------- Utilities สำหรับเส้นทาง ----------
func get_paths() -> Array[Path2D]:
	return paths

func get_path_by_index(i: int) -> Path2D:
	if paths.is_empty(): return null
	return paths[clampi(i, 0, paths.size() - 1)]

func get_random_path() -> Path2D:
	if paths.is_empty(): return null
	return paths[randi() % paths.size()]

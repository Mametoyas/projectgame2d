extends Node

@export var enemy_scene: PackedScene          # ลาก enemy_test.tscn
@export var path_node: NodePath               # ชี้ไปที่ MAP_FOREST1/Path2D_forest1

var _path: Path2D

func _ready():
	_path = get_node_or_null(path_node) as Path2D
	if enemy_scene == null:
		push_error("❌ Enemy Scene ยังไม่ได้ตั้งค่าใน Inspector")
		return
	if _path == null:
		push_error("❌ Path ยังไม่ได้ตั้งค่าไปที่ Path2D_forest1")
		return

	# ปล่อย 5 ตัวทดสอบ
	for i in 5:
		spawn_enemy()

func spawn_enemy():
	if _path == null or enemy_scene == null:
		return
	var pf := PathFollow2D.new()
	pf.rotates = true
	pf.loop = false
	_path.add_child(pf)

	var enemy := enemy_scene.instantiate()
	pf.add_child(enemy)
	pf.progress_ratio = 0.0

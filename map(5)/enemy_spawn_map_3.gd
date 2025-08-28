# enemy_spawn_forest2.gd
extends Node
class_name EnemySpawnerForest3

@export var enemy_scene: PackedScene
@export var paths: Array[Path2D] = [$"../MAP_FOREST3/Forest3Line1",$"../MAP_FOREST3/Forest3Line2",$"../MAP_FOREST3/Forest3Line3",$"../MAP_FOREST3/Forest3Line4",$"../MAP_FOREST3/Forest3Line5",$"../MAP_FOREST3/Forest3Line6"]     # ลาก Forest2Line1/2/3 มาใส่ให้ครบ
@export var base: Node = null             # ลากโหนด BASE (ที่ติด Base.gd)
@export var start_on_ready := true


# ---- ตั้งค่าเวฟ ----
@export var wave_counts: PackedInt32Array = [1, 1, 1]  # ใช้แค่ "จำนวนเวฟ"; ค่าด้านในไม่ใช้นับตัวแล้ว
@export var count_per_path: int = 4                    # ✅ เส้นละกี่ตัวต่อเวฟ
@export var spawn_interval_range := Vector2(0.5, 1.2)  # เวลาระหว่างตัวในเวฟเดียวกัน
@export var delay_between_waves := 5.0                 # เวลาพักหลังศัตรูเวฟหมด (วิ)

signal wave_started(index: int, total: int)
signal wave_finished(index: int, total: int)
signal all_waves_cleared

var _alive := 0
var _running := false

func _ready():
	if start_on_ready:
		start_waves()

func start_waves():
	if _running: return
	_running = true
	_run_waves()

func stop_waves():
	_running = false

func _run_waves() -> void:
	var total := wave_counts.size()
	for i in total:
		if not _running: break
		emit_signal("wave_started", i + 1, total)

		await _run_one_wave()  # ไม่รับพารามิเตอร์แล้ว

		emit_signal("wave_finished", i + 1, total)

		# รอจนศัตรูเวฟนี้หายหมดก่อน
		while _running and _alive > 0:
			await get_tree().process_frame

		# ดีเลย์ก่อนเวฟถัดไป
		if i < total - 1 and _running:
			await get_tree().create_timer(max(delay_between_waves, 0.0)).timeout

	# เวฟสุดท้าย: รอให้หมดก่อนประกาศเคลียร์
	while _running and _alive > 0:
		await get_tree().process_frame
	if _running:
		emit_signal("all_waves_cleared")

func _run_one_wave() -> void:
	if paths.is_empty() or count_per_path <= 0 or enemy_scene == null:
		return

	# รวมทั้งหมดที่จะปล่อยในเวฟนี้ = เส้น * ตัวต่อเส้น
	var total_to_spawn := paths.size() * count_per_path

	# สุ่มจุดเริ่มเส้น เพื่อไม่ให้ทุกเวฟเริ่มจากเส้นเดิม
	var start_idx := randi() % paths.size()

	for i in total_to_spawn:
		if not _running: break
		var path := paths[(start_idx + i) % paths.size()]  # วนรอบทีละเส้น
		_spawn_on_path(path)

		var wait := randf_range(spawn_interval_range.x, spawn_interval_range.y)
		await get_tree().create_timer(max(wait, 0.0)).timeout

func _spawn_on_path(path: Path2D) -> void:
	if path == null: return
	var pf := PathFollow2D.new()
	pf.rotates = true
	pf.loop = false
	path.add_child(pf)

	var e := enemy_scene.instantiate()
	pf.add_child(e)
	pf.progress_ratio = 0.0

	_alive += 1
	e.connect("reached_goal", Callable(self, "_on_enemy_reached_goal"))
	e.connect("tree_exited", Callable(self, "_on_enemy_freed"))

func _on_enemy_reached_goal(dmg: int):
	if base and base.has_method("apply_damage"):
		base.apply_damage(dmg)

func _on_enemy_freed():
	_alive = max(_alive - 1, 0)

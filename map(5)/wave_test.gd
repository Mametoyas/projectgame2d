extends Node
class_name EnemyWaveSpawner

@export var waves: Array[WaveDef] = []       # ← ใส่ WaveDef ตามลำดับเวฟ
@export var paths: Array[Path2D] = []        # ← ลาก Path2D ทั้งหมดของด่าน
@export var base: Node = null                # ← ลากโหนดฐาน (ติด Base.gd มี apply_damage)
@export var spawn_interval_range := Vector2(0.5, 1.2)   # เวลาระหว่าง "ตัว" ในเวฟเดียวกัน
@export var delay_between_waves := 5.0                    # เวลาพักหลังศัตรูเวฟหมด (วินาที)
@export var start_on_ready := true

# (ออปชัน) น้ำหนักสุ่มเส้น ให้บางเส้นมีโอกาสมากกว่า
@export var path_weights: PackedFloat32Array = []   # เช่น [2,1,1] ยาวเท่ากับ paths

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
	var total := waves.size()
	for i in total:
		if not _running: break

		var wave := waves[i]
		emit_signal("wave_started", i+1, total)
		await _run_one_wave(wave)
		emit_signal("wave_finished", i+1, total)

		# รอจนศัตรูเวฟนี้หายจากฉากหมดก่อน
		while _running and _alive > 0:
			await get_tree().process_frame

		# ดีเลย์ก่อนเริ่มเวฟถัดไป
		if i < total-1 and _running:
			await get_tree().create_timer(max(delay_between_waves, 0.0)).timeout

	# เวฟสุดท้าย: รอศัตรูหายหมดก่อนประกาศเคลียร์
	while _running and _alive > 0:
		await get_tree().process_frame
	if _running:
		emit_signal("all_waves_cleared")

func _run_one_wave(wave: WaveDef) -> void:
	if wave == null or wave.enemies.is_empty():
		return

	# สุ่มเลือก index เริ่มต้นของเส้น เพื่อไม่ให้ทุกเวฟเริ่มจากเส้นเดิม
	var start_idx := (paths.is_empty()) ? 0 : randi() % max(paths.size(), 1)

	for econf in wave.enemies:
		var scene := econf.scene
		var count := max(econf.count, 0)
		for n in count:
			if not _running: break
			_spawn_one(scene, start_idx)
			var wait := randf_range(spawn_interval_range.x, spawn_interval_range.y)
			await get_tree().create_timer(max(wait, 0.0)).timeout

func _spawn_one(scene: PackedScene, start_idx: int):
	if scene == null or paths.is_empty(): return
	var path := _pick_path(start_idx)
	if path == null: return

	var pf := PathFollow2D.new()
	pf.rotates = true
	pf.loop = false
	path.add_child(pf)

	var e := scene.instantiate()
	pf.add_child(e)
	pf.progress_ratio = 0.0

	_alive += 1
	# Enemy.gd ต้อง emit สัญญาณ reached_goal(damage) ตอนถึงปลายทาง
	e.connect("reached_goal", Callable(self, "_on_enemy_reached_goal"))
	e.connect("tree_exited", Callable(self, "_on_enemy_freed"))

func _pick_path(start_idx: int) -> Path2D:
	if paths.is_empty(): return null
	# ถ้ามีน้ำหนักครบ ใช้ weighted random
	if path_weights.size() == paths.size():
		var total := 0.0
		for w in path_weights: total += max(w, 0.0)
		if total > 0.0:
			var r := randf() * total
			for i in paths.size():
				r -= max(path_weights[i], 0.0)
				if r <= 0.0:
					return paths[i]
	# ไม่งั้นสุ่มเท่ากัน
	return paths[randi() % paths.size()]

func _on_enemy_reached_goal(dmg: int):
	if base and base.has_method("apply_damage"):
		base.apply_damage(dmg)

func _on_enemy_freed():
	_alive = max(_alive - 1, 0)

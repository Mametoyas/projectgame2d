extends Node
class_name EnemyWaveSpawner4

@export var enemy_scene: PackedScene
@export var paths: Array[Path2D] = [$"../MAP_FOREST4/Forest4Line1"]          # ลาก Path2D ของด่าน (1–หลายเส้น)
@export var base: Node = null                   # ลากโหนด BASE (มี apply_damage)

# ---- ตั้งค่าเวฟ ----
@export var wave_counts: PackedInt32Array = [6, 8, 10]
@export var spawn_interval_range := Vector2(0.5, 1.2)   # เวลาระหว่างมอนในเวฟเดียวกัน
@export var delay_between_waves := 5.0                  # เวลาพักหลังศัตรูเวฟหมด (วิ)
@export var start_on_ready := true

@export var path_weights: PackedFloat32Array = []       # น้ำหนักสุ่มเส้น (optional)

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

		emit_signal("wave_started", i+1, total)
		await _run_one_wave(wave_counts[i])
		emit_signal("wave_finished", i+1, total)

		# ✅ รอจนศัตรูเวฟนี้หายหมดก่อน
		while _running and _alive > 0:
			await get_tree().process_frame

		# ✅ ดีเลย์ 5 วิ ก่อนเริ่มเวฟต่อไป
		if i < total-1 and _running:
			await get_tree().create_timer(max(delay_between_waves, 0.0)).timeout

	# ✅ รอศัตรูเวฟสุดท้ายหายหมดก่อนประกาศเคลียร์
	while _running and _alive > 0:
		await get_tree().process_frame
	if _running:
		emit_signal("all_waves_cleared")

func _run_one_wave(count: int) -> void:
	count = max(count, 0)
	for n in count:
		if not _running: break
		_spawn_one()
		var wait := randf_range(spawn_interval_range.x, spawn_interval_range.y)
		await get_tree().create_timer(max(wait, 0.0)).timeout

func _spawn_one():
	if enemy_scene == null or paths.is_empty(): return
	var path := _pick_path()
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

func _pick_path() -> Path2D:
	if path_weights.size() == paths.size():
		var total := 0.0
		for w in path_weights: total += max(w, 0.0)
		if total > 0.0:
			var r := randf() * total
			for i in paths.size():
				r -= max(path_weights[i], 0.0)
				if r <= 0.0:
					return paths[i]
	# เท่ากันทุกเส้น
	return paths[randi() % paths.size()]

func _on_enemy_reached_goal(dmg: int):
	if base and base.has_method("apply_damage"):
		base.apply_damage(dmg)

func _on_enemy_freed():
	_alive = max(_alive - 1, 0)

# enemy_spawn_multi.gd
extends Node
class_name EnemySpawnerMulti

@export var enemy_scene: PackedScene
@export var paths: Array[Path2D] = [$"../MAP_FOREST2/walking_line/Forest2Line1",$"../MAP_FOREST2/walking_line/Forest2Line2",$"../MAP_FOREST2/walking_line/Forest2Line3"]        # ลาก Forest2Line1/2/3 มาใส่ให้ครบ
@export var waves: Array[SpawnWave] = []     # เพิ่มรายการเวฟใน Inspector ต่อแมพ
@export var auto_start: bool = true

var _rr := 0  # ตัวชี้ของโหมด ROUND_ROBIN

func _ready():
	if auto_start:
		start_all_waves()

# เรียกเล่นเวฟทั้งหมดตามลำดับ
func start_all_waves() -> void:
	for w in waves:
		await get_tree().create_timer(max(w.delay_before, 0.0)).timeout
		await _run_one_wave(w)

# ปล่อยมอน 1 เวฟ ตาม config
func _run_one_wave(w: SpawnWave) -> void:
	var n := w.count
	if w.count_variation > 0:
		n += randi_range(-w.count_variation, w.count_variation)
		n = max(n, 0)
	for i in n:
		_spawn_one(w)
		await get_tree().create_timer(max(w.interval, 0.0)).timeout

func _spawn_one(w: SpawnWave) -> void:
	if enemy_scene == null or paths.is_empty(): return
	var chosen := _pick_path_for_wave(w)
	if chosen == null: return

	var pf := PathFollow2D.new()
	pf.rotates = true
	pf.loop = false
	chosen.add_child(pf)

	var enemy := enemy_scene.instantiate()
	pf.add_child(enemy)
	pf.progress_ratio = 0.0

# เลือกเส้นทางตามโหมดของเวฟ
func _pick_path_for_wave(w: SpawnWave) -> Path2D:
	match w.select_mode:
		SpawnWave.PathSelectMode.PER_ENEMY_RANDOM:
			return paths[randi() % paths.size()]
		SpawnWave.PathSelectMode.ROUND_ROBIN:
			var p := paths[_rr % paths.size()]
			_rr += 1
			return p
		SpawnWave.PathSelectMode.SINGLE_ACTIVE:
			return paths[clampi(w.active_path_index, 0, paths.size() - 1)]
		SpawnWave.PathSelectMode.WEIGHTED_RANDOM:
			return _pick_weighted(w.path_weights)
		_:
			return paths[0]

func _pick_weighted(weights: PackedFloat32Array) -> Path2D:
	var n := paths.size()
	if n == 0: return null
	if weights.size() != n:
		var tmp := PackedFloat32Array()
		for i in n: tmp.push_back(1.0)
		weights = tmp

	var total := 0.0
	for w in weights: total += max(w, 0.0)
	if total <= 0.0: return paths[randi() % n]

	var r := randf() * total
	for i in n:
		r -= max(weights[i], 0.0)
		if r <= 0.0:
			return paths[i]
	return paths[n - 1]

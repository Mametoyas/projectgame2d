# res://spawner/spawner_multi_path_boss.gd
extends Node

@onready var wave_timer: Timer = $WaveTimer
@onready var next_button: Button = $NextWaveButton

var factory: Node = null         # enemy_factory (จะหาแบบขยันมือ)
var boss_factory: Node = null    # boss_factory  (จะหาแบบขยันมือ)

var waves: Array = [
	["boss"],
	["splitter","splitter","splitter","splitter","splitter"],
	["tank","crawler","runner","regenerator","runner"],
	["shielded","shielded","splitter","runner","flyer","flyer","splitter","splitter","splitter"]
]

var current_wave: int = 0
var queue_in_wave: Array = []
var wave_spawning: bool = false
var waiting_for_clear: bool = false

func _ready() -> void:
	randomize()

	if next_button and not next_button.pressed.is_connected(_on_next_wave_button_pressed):
		next_button.pressed.connect(_on_next_wave_button_pressed)
	if wave_timer and not wave_timer.timeout.is_connected(_on_wave_timer_timeout):
		wave_timer.timeout.connect(_on_wave_timer_timeout)

	# หน่วง 1 เฟรมให้โรงงานเรียก add_to_group() ให้เสร็จ
	call_deferred("_after_ready")

func _after_ready() -> void:
	_resolve_factories()
	_prepare_next_wave()

func _process(_delta: float) -> void:
	if waiting_for_clear:
		var alive: Array = get_tree().get_nodes_in_group("enemies")
		if alive.is_empty():
			waiting_for_clear = false
			current_wave += 1
			_prepare_next_wave()

# ------- หาโรงงานแบบขยันมือทุกครั้งที่ต้องใช้ -------
func _resolve_factories() -> void:
	if factory == null:
		factory = get_tree().get_first_node_in_group("enemy_factory")
	if boss_factory == null:
		boss_factory = get_tree().get_first_node_in_group("boss_factory")

# ------- UI คุมเวฟ -------
func _prepare_next_wave() -> void:
	if current_wave >= waves.size():
		if next_button:
			next_button.text = "All waves cleared!"
			StageProgress.unlock_next_if_cleared(5)
			next_button.disabled = true
			next_button.visible = true
		return
	if next_button:
		next_button.text = "Start Wave %d/%d" % [current_wave + 1, waves.size()]
		next_button.disabled = false
		next_button.visible = true

func _on_next_wave_button_pressed() -> void:
	if next_button:
		next_button.disabled = true
		next_button.visible = false
	start_wave()

func start_wave() -> void:
	_resolve_factories()  # เช็คอีกทีเผื่อยังไม่พร้อม
	if current_wave >= waves.size():
		return
	queue_in_wave = waves[current_wave].duplicate()
	wave_timer.wait_time = 0.6
	wave_timer.start()
	wave_spawning = true
	waiting_for_clear = false

func _on_wave_timer_timeout() -> void:
	if queue_in_wave.is_empty():
		wave_timer.stop()
		wave_spawning = false
		waiting_for_clear = true
		return
	var type_id: String = String(queue_in_wave.pop_front())
	spawn_enemy(type_id)

# ------- เลือกเส้นทางแบบสุ่ม (Path2D ที่มีลูกชื่อ SeedFollow ใต้พาเรนต์เดียวกัน) -------
func _pick_path_and_pf() -> Dictionary:
	var result: Dictionary = {}
	var parent_node := get_parent()
	if parent_node == null:
		return result

	var candidates: Array[Path2D] = []
	for c in parent_node.get_children():
		if c is Path2D and c.has_node("SeedFollow"):
			candidates.append(c)

	if candidates.is_empty():
		return result

	var path: Path2D = candidates[randi() % candidates.size()]
	var seed_follow: PathFollow2D = path.get_node("SeedFollow") as PathFollow2D
	if seed_follow == null:
		return result

	var pf: PathFollow2D = seed_follow.duplicate() as PathFollow2D
	pf.progress = 0.0
	path.add_child(pf)

	result["path"] = path
	result["pf"] = pf
	return result

# ------- สปอว์นศัตรู/บอส -------
func spawn_enemy(type_id: String) -> void:
	var pick := _pick_path_and_pf()
	if pick.is_empty():
		return
	var pf: PathFollow2D = pick["pf"]

	# บอส
	if type_id == "boss" or type_id.begins_with("boss:"):
		if boss_factory == null:
			_resolve_factories()
		if boss_factory == null:
			return
		var boss_id := "boss"
		if type_id.begins_with("boss:"):
			boss_id = type_id.substr(5)

		if boss_factory.has_method("spawn"):
			var b: Node2D = boss_factory.call("spawn", boss_id, pf) as Node2D
			if b:
				get_tree().current_scene.add_child(b)
				b.global_position = pf.global_position
				# ต่อสัญญาณแบบ deferred + one-shot กันพังตอนเปลี่ยนฉาก
				if b.has_signal("died") and not b.is_connected("died", Callable(self, "_on_enemy_died")):
					b.connect("died", Callable(self, "_on_enemy_died"), CONNECT_DEFERRED | CONNECT_ONE_SHOT)
		return

	# ศัตรูปกติ
	if factory == null:
		_resolve_factories()
	if factory == null:
		return

	if factory.has_method("spawn"):
		var e: Node2D = factory.call("spawn", type_id, pf) as Node2D
		if e:
			get_tree().current_scene.add_child(e)
			e.global_position = pf.global_position
			# ต่อสัญญาณแบบ deferred + one-shot
			if e.has_signal("died") and not e.is_connected("died", Callable(self, "_on_enemy_died")):
				e.connect("died", Callable(self, "_on_enemy_died"), CONNECT_DEFERRED | CONNECT_ONE_SHOT)

# ------- รับเงินเมื่อศัตรู/บอสตาย -------
func _on_enemy_died(reward: int) -> void:
	# ถ้าหน้านี้ถูกถอดจาก tree (เช่นเพราะเปลี่ยนฉาก) ให้เลิกทำงานทันที
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return

	var hud := tree.get_first_node_in_group("hud")
	if hud and hud.has_method("add_money"):
		hud.call("add_money", reward)
	#if hud and hud.has_node("BuildUI"):
		#var ui := hud.get_node("BuildUI")
		#if ui and ui.has_method("add_money"):
			#ui.call("add_money", reward)

extends Node

@onready var paths: Array[Path2D] = [
	$"../Forest5Line1",
	$"../Forest5Line2",
	$"../Forest5Line3",
	$"../Forest5Line4",
	$"../Forest5Line5",
	$"../Forest5Line6",
	$"../Forest5Line7",
	$"../Forest5Line8",
	$"../Forest5Line9"
]


@onready var factory: EnemyFactory = get_tree().get_first_node_in_group("enemy_factory") as EnemyFactory
@onready var boss_factory: BossFactory = get_tree().get_first_node_in_group("boss_factory") as BossFactory

@onready var wave_timer: Timer = $WaveTimer
@onready var next_button: Button = $NextWaveButton

var waves: Array = [
	["money","money","money","money"],
	["splitter","splitter","splitter","splitter","splitter"],
	["tank","crawler","runner","regenerator","runner"],
	["shielded","shielded","splitter","runner","flyer","flyer","splitter","splitter","splitter"]
]

var current_wave: int = 0
var queue_in_wave: Array = []
var wave_spawning: bool = false
var waiting_for_clear: bool = false

func _ready() -> void:
	# ต่อสัญญาณปุ่ม
	if next_button and not next_button.pressed.is_connected(_on_next_wave_button_pressed):
		next_button.pressed.connect(_on_next_wave_button_pressed)
	# ✅ ต่อสัญญาณเวฟไทเมอร์ (ที่คุณยังไม่ได้ต่อ)
	if wave_timer and not wave_timer.timeout.is_connected(_on_wave_timer_timeout):
		wave_timer.timeout.connect(_on_wave_timer_timeout)

	_prepare_next_wave()

func _process(_delta: float) -> void:
	if waiting_for_clear:
		var alive: Array = get_tree().get_nodes_in_group("enemies")
		if alive.is_empty():
			waiting_for_clear = false
			current_wave += 1
			_prepare_next_wave()

func _prepare_next_wave() -> void:
	if current_wave >= waves.size():
		if next_button:
			next_button.text = "All waves cleared!"
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

func spawn_enemy(type_id: String) -> void:
	# ---- สุ่มเลือกเส้นทาง ----
	if paths.is_empty():
		print("[SPAWNER] paths ว่าง")
		return

	var path: Path2D = paths.pick_random()
	if path == null:
		print("[SPAWNER] path เป็น null")
		return

	var seed_follow: PathFollow2D = path.get_node_or_null("SeedFollow") as PathFollow2D
	if seed_follow == null:
		print("[SPAWNER] ไม่มี SeedFollow ใน: ", path.name)
		return

	var pf := seed_follow.duplicate() as PathFollow2D
	pf.progress = 0.0
	path.add_child(pf)

	print("[SPAWNER] Spawn ", type_id, " ที่เส้นทาง: ", path.name)

	# ---- ถ้าเป็นบอส ----
	if type_id == "boss":
		if boss_factory == null:
			print("[SPAWNER] boss_factory null")
			return
		var b: Boss = boss_factory.spawn("boss", pf) as Boss
		if b:
			get_parent().add_child(b)
			b.global_position = pf.global_position
			print("[SPAWNER] Boss spawn ที่ ", path.name)
			if not b.died.is_connected(_on_enemy_died):
				b.died.connect(_on_enemy_died)
		return

	# ---- ศัตรูปกติ ----
	if factory == null:
		print("[SPAWNER] enemy_factory null")
		return
	var e: Enemy = factory.spawn(type_id, pf)
	if e:
		get_parent().add_child(e)
		e.global_position = pf.global_position
		print("[SPAWNER] Enemy spawn ที่ ", path.name)
		if not e.died.is_connected(_on_enemy_died):
			e.died.connect(_on_enemy_died)


# ---------- รับเงินเมื่อศัตรู/บอสตาย ----------
func _on_enemy_died(reward: int) -> void:
	# เติมเงินเข้า HUD
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("add_money"):
		hud.call("add_money", reward)

	# ถ้า UI สร้างเงินเองผ่าน BuildUI ให้ซิงก์ด้วย (แล้วแต่โปรเจกต์คุณ)
	if hud and hud.has_node("BuildUI"):
		var ui := hud.get_node("BuildUI")
		if ui and ui.has_method("add_money"):
			ui.call("add_money", reward)

extends Node

@onready var path2d: Path2D = $"../Path2D_forest1"
@onready var seed_follow: PathFollow2D = $"../Path2D_forest1/SeedFollow"
@onready var factory = get_tree().get_first_node_in_group("enemy_factory") # อย่า type เป็น EnemyFactory เพื่อกันชนชื่อคลาส
@onready var wave_timer: Timer = $WaveTimer
@onready var next_button: Button = $NextWaveButton

const AUTO_START := false  # ตั้งเป็น true เพื่อให้เริ่ม wave อัตโนมัติไว้เทส

const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")
const SND_WIN := preload("res://audio/NEW_Winning all wave.wav")
	#SFX.play_ui(SND_WIN)


var waves = [
	["money"],
	["runner"],
	["runner"]
]

var current_wave := 0
var queue_in_wave := []
var wave_spawning := false
var waiting_for_clear := false

func _ready() -> void:
	if factory == null:
		factory = get_tree().get_first_node_in_group("enemy_factory")

	# ต่อสัญญาณให้ชัวร์ (กันลืมต่อใน Editor)
	if next_button and not next_button.pressed.is_connected(_on_next_wave_button_pressed):
		next_button.pressed.connect(_on_next_wave_button_pressed)
	if wave_timer and not wave_timer.timeout.is_connected(_on_wave_timer_timeout):
		wave_timer.timeout.connect(_on_wave_timer_timeout)

	_prepare_next_wave()

	if AUTO_START:
		start_wave()

func _process(_delta: float) -> void:
	# ถ้าปล่อยครบแล้วรอจนศัตรูหมด
	if waiting_for_clear:
		var alive := get_tree().get_nodes_in_group("enemies")
		if alive.is_empty():
			waiting_for_clear = false
			current_wave += 1
			_prepare_next_wave()

func _prepare_next_wave() -> void:
	if current_wave >= waves.size():
		if next_button:
			next_button.text = "All waves cleared!"
			StageProgress.unlock_next_if_cleared(1)
			SFX.play_ui(SND_WIN)
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
	# รีโซลฟ์โรงงานแบบขยันมือ – เผื่อยังไม่พร้อมตอน _ready()
	if factory == null:
		factory = get_tree().get_first_node_in_group("enemy_factory")
		
	var f: PathFollow2D = seed_follow.duplicate() as PathFollow2D
	if f == null:
		return
	f.progress = 0.0
	path2d.add_child(f)

	var e = null
	if factory.has_method("spawn"):
		e = factory.spawn(type_id, f)
	if e:
		get_parent().add_child(e)
		e.global_position = f.global_position
		if not e.died.is_connected(_on_enemy_died):
			e.died.connect(_on_enemy_died)

func _on_enemy_died(reward: int) -> void:
	if not is_inside_tree():
		return
	# เติมเงินเข้าที่ HUD
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("add_money"):
		hud.call("add_money", reward)

	# ถ้าใช้ BuildUI ให้ซิงก์ค่าเงินด้วย
	#var ui: Node = null        # <<< ใส่ชนิดให้ชัดเจน
	#if hud != null and hud.has_node("BuildUI"):
		#ui = hud.get_node("BuildUI")
	#if ui != null and ui.has_method("add_money"):
		#ui.call("add_money", reward)

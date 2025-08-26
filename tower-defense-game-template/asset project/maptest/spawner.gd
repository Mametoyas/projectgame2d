extends Node

@onready var path2d: Path2D = $"../Path2D"
@onready var seed_follow: PathFollow2D = $"../Path2D/SeedFollow"
@onready var factory: EnemyFactory = get_tree().get_first_node_in_group("enemy_factory") as EnemyFactory
@onready var wave_timer: Timer = $WaveTimer
@onready var next_button: Button = $NextWaveButton

var waves = [
	["flyer","flyer","crawler"],
	["tank","crawler","runner","regenerator","runner"],
	["shielded","shielded","splitter","runner","flyer","flyer","splitter","splitter","splitter"]
]

var current_wave := 0
var queue_in_wave := []
var wave_spawning := false        # กำลังปล่อยศัตรู
var waiting_for_clear := false    # ปล่อยครบแล้ว กำลังรอศัตรูในฉากหมด

func _ready() -> void:
	# ต่อสัญญาณปุ่ม (กันต่อซ้ำ)
	if next_button and not next_button.pressed.is_connected(_on_next_wave_button_pressed):
		next_button.pressed.connect(_on_next_wave_button_pressed)
	_prepare_next_wave()  # ยังไม่เริ่มจนกว่าจะกดปุ่ม

func _process(_delta: float) -> void:
	# ถ้าปล่อยครบแล้ว รอจนศัตรูในฉากหมดค่อยเปิดปุ่มต่อไป
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
			next_button.disabled = true
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
	if current_wave >= waves.size(): return
	queue_in_wave = waves[current_wave].duplicate()
	wave_timer.wait_time = 0.6
	wave_timer.start()
	wave_spawning = true
	waiting_for_clear = false

func _on_wave_timer_timeout() -> void:
	if queue_in_wave.is_empty():
		wave_timer.stop()
		wave_spawning = false
		waiting_for_clear = true   # ปล่อยครบแล้ว → รอเคลียร์ศัตรูให้หมด
		return
	var type_id: String = String(queue_in_wave.pop_front())
	spawn_enemy(type_id)

func spawn_enemy(type_id: String) -> void:
	if factory == null or seed_follow == null or path2d == null: return
	var f: PathFollow2D = seed_follow.duplicate() as PathFollow2D
	f.progress = 0.0
	path2d.add_child(f)
	var e: Enemy = factory.spawn(type_id, f)
	if e:
		get_parent().add_child(e)
		e.global_position = f.global_position

extends Node

@onready var factory = get_tree().get_first_node_in_group("enemy_factory")
@onready var wave_timer: Timer = $WaveTimer
@onready var next_button: Button = $NextWaveButton

# เก็บเส้นทางทั้งหมดใน Array
@onready var paths: Array[Path2D] = [
	$"../Forest4Line1",
	$"../Forest4Line2",
]

const SND_WIN := preload("res://audio/NEW_Winning all wave.wav")
	#SFX.play_ui(SND_WIN)

const AUTO_START := false

var waves = [
	["HarpoonFish","HarpoonFish","HarpoonFish","money","fish1","fish1","fish1"],
	["tank","HarpoonFish","fish1","regenerator","HarpoonFish","fish1","money"],
	["Minotaur","shielded","shielded","splitter","runner","flyer"]
]

var current_wave := 0
var queue_in_wave := []
var wave_spawning := false
var waiting_for_clear := false

func _ready() -> void:
	if factory == null:
		factory = get_tree().get_first_node_in_group("enemy_factory")

	if next_button and not next_button.pressed.is_connected(_on_next_wave_button_pressed):
		next_button.pressed.connect(_on_next_wave_button_pressed)
	if wave_timer and not wave_timer.timeout.is_connected(_on_wave_timer_timeout):
		wave_timer.timeout.connect(_on_wave_timer_timeout)

	_prepare_next_wave()
	if AUTO_START:
		start_wave()

func _process(_delta: float) -> void:
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
			StageProgress.unlock_next_if_cleared(4)
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
	if factory == null:
		factory = get_tree().get_first_node_in_group("enemy_factory")

	# สุ่มเลือกเส้นทาง
	var chosen_path: Path2D = paths[randi() % paths.size()]
	var seed_follow: PathFollow2D = chosen_path.get_node("SeedFollow") as PathFollow2D
	if seed_follow == null:
		return

	var f: PathFollow2D = seed_follow.duplicate() as PathFollow2D
	f.progress = 0.0
	chosen_path.add_child(f)

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

	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("add_money"):
		hud.call("add_money", reward)

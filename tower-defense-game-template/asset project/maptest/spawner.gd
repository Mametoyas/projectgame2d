extends Node

@onready var path2d: Path2D = $"../Path2D"
@onready var seed_follow: PathFollow2D = $"../Path2D/SeedFollow"
@onready var factory: EnemyFactory = get_tree().get_first_node_in_group("enemy_factory") as EnemyFactory
@onready var wave_timer: Timer = $WaveTimer

var waves = [
	["crawler","crawler","runner","runner","crawler"],
	["tank","crawler","runner","regenerator","runner"],
	["shielded","shielded","splitter","runner","flyer","flyer"]
]

var current_wave := 0
var queue_in_wave := []   # ← เอา type ออก

func _ready() -> void:
	start_wave()

func start_wave() -> void:
	if current_wave >= waves.size(): return
	queue_in_wave = waves[current_wave].duplicate()
	wave_timer.wait_time = 0.6
	wave_timer.start()

func _on_wave_timer_timeout() -> void:
	if queue_in_wave.is_empty():
		wave_timer.stop()
		current_wave += 1
		await get_tree().create_timer(2.0).timeout
		start_wave()
		return
	var type_id: String = String(queue_in_wave.pop_front())
	spawn_enemy(type_id)

func spawn_enemy(type_id: String):
	if factory == null or seed_follow == null or path2d == null: return
	var f: PathFollow2D = seed_follow.duplicate() as PathFollow2D
	f.progress = 0.0
	path2d.add_child(f)
	var e: Enemy = factory.spawn(type_id, f)
	if e:
		get_parent().add_child(e)
		e.global_position = f.global_position

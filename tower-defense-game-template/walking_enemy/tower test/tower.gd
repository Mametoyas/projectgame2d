extends Node2D

@export var damage: int = 15
@export var range_radius: float = 120.0
@export var shoot_interval: float = 0.6
@export var bullet_scene: PackedScene
@export var can_target_flying: bool = false   # <-- เพิ่มสวิตช์นี้

@onready var range_area: Area2D = $Range
@onready var shape: CollisionShape2D = $Range/CollisionShape2D
@onready var shoot_timer: Timer = $ShootTimer

var target: Enemy = null
var in_range: Array[Enemy] = []

func _ready() -> void:
	var c := shape.shape as CircleShape2D
	if c: c.radius = range_radius
	range_area.monitoring = true
	range_area.monitorable = true
	if not range_area.area_entered.is_connected(_on_area_entered):
		range_area.area_entered.connect(_on_area_entered)
	if not range_area.area_exited.is_connected(_on_area_exited):
		range_area.area_exited.connect(_on_area_exited)
	shoot_timer.wait_time = shoot_interval
	if not shoot_timer.timeout.is_connected(_on_shoot):
		shoot_timer.timeout.connect(_on_shoot)
	shoot_timer.autostart = true
	shoot_timer.start()

func _process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_pick_target()
	# ถ้าเผลอได้เป้าบินมาและห้ามยิง -> เลือกใหม่
	elif not can_target_flying and target.is_in_group("flying_enemies"):
		_pick_target()

func _on_area_entered(a: Area2D) -> void:
	var e := a.get_parent()
	if e and e.is_in_group("enemies"):
		# << กรองตัวบินออก ถ้า can_target_flying = false >>
		if not can_target_flying and e.is_in_group("flying_enemies"):
			return
		var enemy := e as Enemy
		if enemy != null and not in_range.has(enemy):
			in_range.append(enemy)
			if target == null:
				_pick_target()

func _on_area_exited(a: Area2D) -> void:
	var e := a.get_parent()
	if e and e is Enemy:
		var enemy := e as Enemy
		if in_range.has(enemy):
			in_range.erase(enemy)
		if enemy == target:
			_pick_target()

func _pick_target() -> void:
	# ล้าง invalid + กรองบินตามสวิตช์อีกชั้นเพื่อความชัวร์
	var cleaned: Array[Enemy] = []
	for e in in_range:
		if e != null and is_instance_valid(e):
			if can_target_flying or not e.is_in_group("flying_enemies"):
				cleaned.append(e)
	in_range = cleaned

	if in_range.is_empty():
		target = null
		return

	in_range.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)
	target = in_range[0]

func _on_shoot() -> void:
	if target == null or not is_instance_valid(target):
		return
	if bullet_scene:
		var b := bullet_scene.instantiate() as Area2D
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		b.look_at(target.global_position)
		b.set("damage", damage)
		b.set("dir", (target.global_position - global_position).normalized())
	else:
		target.apply_damage(damage)

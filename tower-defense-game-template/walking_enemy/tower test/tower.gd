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
		
# ===== Range helpers (add to tower.gd) =====

func get_effective_range_radius() -> float:
	var area: Area2D = get_node_or_null("Range") as Area2D
	if area == null:
		return 0.0

	var cs: CollisionShape2D = area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var base: float = 0.0

	# 1) ใช้ค่าจาก Shape ถ้ามี
	if cs and cs.shape is CircleShape2D:
		base = (cs.shape as CircleShape2D).radius
	else:
		# 2) ไม่งั้น fallback เป็น export var range_radius ที่มีอยู่ใน tower.gd
		base = float(range_radius)

	# คูณสเกลของ Range ให้ตรงกับของจริง
	var s: float = max(abs(area.global_scale.x), abs(area.global_scale.y))
	return base * (s if s > 0.0 else 1.0)

var _range_line: Line2D = null

func _ensure_range_line() -> Line2D:
	var area: Area2D = get_node_or_null("Range") as Area2D
	if area == null:
		return null
	var line: Line2D = area.get_node_or_null("RangeCircle") as Line2D
	if line == null:
		line = Line2D.new()
		line.name = "RangeCircle"
		line.width = 2.0
		line.default_color = Color(0, 1, 0, 0.5)
		line.closed = true
		line.visible = false  # ซ่อนเป็นค่าเริ่มต้น
		area.add_child(line)
	_range_line = line
	return line

func _update_range_visual() -> void:
	var line := _ensure_range_line()
	if line == null:
		return
	var r: float = get_effective_range_radius()
	var segs: int = 64
	var pts := PackedVector2Array()
	for i in segs:
		var ang: float = TAU * float(i) / float(segs)
		pts.append(Vector2(cos(ang), sin(ang)) * r)
	line.points = pts

func show_range(show: bool) -> void:
	var line := _ensure_range_line()
	if line == null:
		return
	if show:
		_update_range_visual()
	line.visible = show

extends Node2D

@export var damage: int = 15
@export var range_radius: float = 1200.0
@export var shoot_interval: float = 0.6
@export var bullet_scene: PackedScene
@export var can_target_flying: bool = false

# --------- เลือกวิธีหาจุดยิง (ไม่ต้องมี Marker2D) ----------
@export_enum("OFFSET", "UP_VECTOR", "SPRITE_TOP") var spawn_mode: int = 0
@export var muzzle_local: Vector2 = Vector2(0, -32)   # ใช้เมื่อโหมด OFFSET
@export var barrel_length: float = 128.0               # ใช้เมื่อโหมด UP_VECTOR/SPRITE_TOP
@onready var sprite2d: Sprite2D = $Sprite2D           # ใช้เมื่อโหมด SPRITE_TOP
# -------------------------------------------------------------

@onready var range_area: Area2D = $Range
@onready var shape: CollisionShape2D = $Range/CollisionShape2D
@onready var shoot_timer: Timer = $ShootTimer
var range_preview: Line2D = null

var target: Enemy = null
var in_range: Array[Enemy] = []

func _ready() -> void:
	var c := shape.shape as CircleShape2D
	if c:
		c.radius = range_radius

	range_area.monitoring = true
	range_area.monitorable = true

	if not range_area.area_entered.is_connected(_on_area_entered):
		range_area.area_entered.connect(_on_area_entered)
	if not range_area.area_exited.is_connected(_on_area_exited):
		range_area.area_exited.connect(_on_area_exited)

	shoot_timer.wait_time = shoot_interval
	if not shoot_timer.timeout.is_connected(_on_shoot):
		shoot_timer.timeout.connect(_on_shoot)
	shoot_timer.start()

# ===== จุดยิงแบบไม่ใช้ Marker2D =====
func _get_spawn_pos() -> Vector2:
	match spawn_mode:
		0: # OFFSET (ออฟเซ็ตโลคัล → โกลบอล)
			return to_global(muzzle_local)
		1: # UP_VECTOR (ทิศบนของป้อม * ระยะ)
			var up := Vector2.UP.rotated(rotation)   # (0,-1) หมุนตามป้อม
			return global_position + up * barrel_length
		2: # SPRITE_TOP (ขอบบนของสไปรต์ + ระยะเผื่อ)
			var h := 0.0
			if sprite2d and sprite2d.texture:
				h = abs(sprite2d.scale.y) * float(sprite2d.texture.get_height())
			# ถ้า Sprite2D.centered = true, ขอบบนอยู่ที่ -h/2 ในโลคัล
			var spawn_local := Vector2(0, -(h * 0.5 + barrel_length))
			return to_global(spawn_local)
		_:
			return global_position

# ===== ฟังก์ชันแสดง/ซ่อนวงรัศมี =====
func show_range(enable: bool) -> void:
	if enable:
		if range_preview and is_instance_valid(range_preview):
			range_preview.queue_free()
		range_preview = Line2D.new()
		range_preview.width = 2.0
		range_preview.default_color = Color(0, 1, 1, 0.5)
		range_preview.closed = true

		var points: PackedVector2Array = []
		var segs := 64
		for i in range(segs):
			var angle: float = TAU * float(i) / float(segs)
			points.append(Vector2(cos(angle), sin(angle)) * range_radius)
		range_preview.points = points
		add_child(range_preview)
	else:
		if range_preview and is_instance_valid(range_preview):
			range_preview.queue_free()
		range_preview = null

func _process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_pick_target()
	elif not can_target_flying and target.is_in_group("flying_enemies"):
		_pick_target()

func _on_area_entered(a: Area2D) -> void:
	var e := a.get_parent()
	if e and e.is_in_group("enemies"):
		if not can_target_flying and e.is_in_group("flying_enemies"):
			return
		var enemy := e as Enemy
		if enemy and not in_range.has(enemy):
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
	var cleaned: Array[Enemy] = []
	for e in in_range:
		if e and is_instance_valid(e):
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
	if bullet_scene == null:
		target.apply_damage(damage)
		return

	var b := bullet_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(b)
	b.z_index = 300    
	var spawn_pos := _get_spawn_pos()
	b.global_position = spawn_pos
	b.look_at(target.global_position)
	b.set("damage", damage)
	b.set("dir", (target.global_position - spawn_pos).normalized())

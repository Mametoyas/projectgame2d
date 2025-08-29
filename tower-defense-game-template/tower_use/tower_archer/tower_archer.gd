extends Node2D

# ======== ปรับได้จาก Inspector ========
@export var current_level: int = 1        # 1..3
@export var can_target_flying: bool = false
@export var bullet_scene: PackedScene

# ======== โครงเลเวล 1..3 ========
const LEVELS := [
	{}, # index 0 ไม่ใช้
	{   # Lv1
		"damage": 6,
		"range": 140.0,
		"interval": 0.65,
		"anim": "lv1_idle",
		"cost": 0,
		"bullet": preload("res://tower_use/tower_archer/arrow_archer_tower.tscn"),
		"muzzles": ["MuzzleLv1"]
	},
	{   # Lv2
		"damage": 6,
		"range": 170.0,
		"interval": 0.55,
		"anim": "lv2_idle",
		"cost": 50,
		"bullet": preload("res://tower_use/tower_archer/arrow_archer_tower.tscn"),
		"muzzles": ["MuzzleLv2_Left", "MuzzleLv2_Right"]
	},
	{   # Lv3
		"damage": 6,
		"range": 210.0,
		"interval": 0.45,
		"anim": "lv3_idle",
		"cost": 90,
		"bullet": preload("res://tower_use/tower_archer/arrow_archer_tower.tscn"),
		"muzzles": ["MuzzleLv3_Left", "MuzzleLv3_Right", "MuzzleLv3_Center"]
	}
]


# ======== refs ========
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var range_area: Area2D       = $Range
@onready var range_shape: CollisionShape2D = $Range/CollisionShape2D
@onready var shoot_timer: Timer       = $ShootTimer
@onready var footprint: Area2D        = $BuildFootprint
var muzzles: Array[Marker2D] = []

# สเตตัส runtime
var damage: int = 10
var range_radius: float = 120.0
var shoot_interval: float = 0.6

# ยิง
var target: Enemy = null
var in_range: Array[Enemy] = []

# วงรัศมีโชว์ (ตอนต้องการ debug หรือกดปุ่ม)
var range_preview: Line2D = null

func _ready() -> void:
	range_area.monitoring = true
	range_area.monitorable = true
	range_area.collision_layer = 0
	_set_range_mask()

	if not range_area.area_entered.is_connected(_on_area_entered):
		range_area.area_entered.connect(_on_area_entered)
	if not range_area.area_exited.is_connected(_on_area_exited):
		range_area.area_exited.connect(_on_area_exited)

	_apply_level()

	shoot_timer.wait_time = shoot_interval
	if not shoot_timer.timeout.is_connected(_on_shoot):
		shoot_timer.timeout.connect(_on_shoot)
	shoot_timer.autostart = true
	shoot_timer.start()

	z_index = 50
	if sprite:
		sprite.z_index = 50

func _process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_pick_target()
	else:
		if not can_target_flying and target.is_in_group("flying_enemies"):
			_pick_target()

# ====== Level / Upgrade ======
func _apply_level() -> void:
	var lv: int = clamp(current_level, 1, 3)
	var cfg: Dictionary = LEVELS[lv] as Dictionary

	damage = int(cfg["damage"])
	range_radius = float(cfg["range"])
	shoot_interval = float(cfg["interval"])

	# bullet ที่ใช้ในเลเวลนี้
	if cfg.has("bullet"):
		bullet_scene = cfg["bullet"]

	# muzzles ที่ใช้ในเลเวลนี้
	muzzles.clear()
	if cfg.has("muzzles"):
		for mname in cfg["muzzles"]:
			var m: Marker2D = get_node_or_null(mname) as Marker2D
			if m:
				muzzles.append(m)

	var cs: CircleShape2D = range_shape.shape as CircleShape2D
	if cs:
		cs.radius = range_radius

	shoot_timer.wait_time = shoot_interval

	if sprite and sprite.sprite_frames and cfg.has("anim"):
		var anim_name: String = String(cfg["anim"])
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)

	_set_range_mask()


func get_upgrade_cost() -> int:
	if current_level >= 3:
		return 0
	return int((LEVELS[current_level + 1] as Dictionary)["cost"])

func upgrade() -> bool:
	if current_level >= 3:
		return false
	current_level += 1
	_apply_level()
	return true

func _set_range_mask() -> void:
	range_area.collision_mask = 0
	range_area.set_collision_mask_value(1, true)
	if can_target_flying:
		range_area.set_collision_mask_value(2, true)

# ====== วงรัศมีแสดง/ซ่อน (ถ้าต้องการ) ======
func show_range(enabled: bool) -> void:
	# หา range_area แบบปลอดภัย (กรณี _ready() ยังไม่ทำงาน)
	if range_area == null:
		range_area = get_node_or_null("Range") as Area2D

	if enabled:
		if range_preview != null and is_instance_valid(range_preview):
			range_preview.queue_free()

		range_preview = Line2D.new()
		range_preview.width = 2.0
		range_preview.default_color = Color(0, 1, 1, 0.45)
		range_preview.closed = true

		var pts := PackedVector2Array()
		var segs := 64
		var i := 0
		while i < segs:
			var ang := TAU * float(i) / float(segs)
			pts.append(Vector2(cos(ang), sin(ang)) * range_radius)
			i += 1
		range_preview.points = pts

		# เลือก parent ที่จะ add_child
		var parent_node: Node = self
		if range_area != null:
			parent_node = range_area
		parent_node.add_child(range_preview)

	else:
		if range_preview != null and is_instance_valid(range_preview):
			range_preview.queue_free()
		range_preview = null



# ====== เลือกเป้าหมาย / ยิง ======
func _on_area_entered(a: Area2D) -> void:
	var e: Node = a.get_parent()
	if e != null and e.is_in_group("enemies"):
		if not can_target_flying and e.is_in_group("flying_enemies"):
			return
		var enemy: Enemy = e as Enemy
		if enemy != null and not in_range.has(enemy):
			in_range.append(enemy)
			if target == null:
				_pick_target()

func _on_area_exited(a: Area2D) -> void:
	var e: Node = a.get_parent()
	if e != null and e is Enemy:
		var enemy: Enemy = e as Enemy
		if in_range.has(enemy):
			in_range.erase(enemy)
		if enemy == target:
			_pick_target()

func _pick_target() -> void:
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
		if muzzles.is_empty():
			# fallback ยิงจากกลางป้อม
			_spawn_bullet(global_position)
		else:
			for m in muzzles:
				if m and is_instance_valid(m):
					_spawn_bullet(m.global_position)
	else:
		target.apply_damage(damage)


func _spawn_bullet(pos: Vector2) -> void:
	var b: Area2D = bullet_scene.instantiate() as Area2D

	# หา parent ที่จะใส่กระสุนลงไป (กัน current_scene เป็น null)
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_tree().root

	parent.add_child(b)

	b.z_index = 300
	b.global_position = pos
	b.look_at(target.global_position)
	b.set("damage", damage)
	b.set("dir", (target.global_position - pos).normalized())



# ====== ยูทิล: บอกระยะจริง (เผื่อระบบอื่นเรียกใช้) ======
func get_effective_range_radius() -> float:
	var cs: CircleShape2D = range_shape.shape as CircleShape2D
	if cs == null:
		return range_radius
	var r: float = cs.radius
	var sx: float = abs(range_area.global_scale.x)
	var sy: float = abs(range_area.global_scale.y)
	var s: float = sx
	if sy > s:
		s = sy
	if s <= 0.0:
		s = 1.0
	return r * s

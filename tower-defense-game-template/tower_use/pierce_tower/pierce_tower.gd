extends Node2D

@export var current_level: int = 1
@export var can_target_flying: bool = false

const LEVELS: Array = [
	{}, # unused
	{ "damage": 6,  "range": 150.0, "interval": 0.65, "anim": "lv1_idle",
	  "cost": 0,  "bullet": preload("res://tower_use/pierce_tower/pierce_bullet.tscn"),
	  "muzzles": ["MuzzleLv1"] },
	{ "damage": 9,  "range": 180.0, "interval": 0.55, "anim": "lv2_idle",
	  "cost": 60, "bullet": preload("res://tower_use/pierce_tower/pierce_bulletlv2.tscn"),
	  "muzzles": ["MuzzleLv1"] },
	{ "damage": 12, "range": 210.0, "interval": 0.45, "anim": "lv3_idle",
	  "cost": 100,"bullet": preload("res://tower_use/pierce_tower/pierce_bulletlv3.tscn"),
	  "muzzles": ["MuzzleLv1"] }
]

@onready var sprite_base: AnimatedSprite2D = $SpriteBase
@onready var sprite_top: AnimatedSprite2D  = $SpriteTop
@onready var range_area: Area2D = $Range
@onready var range_shape: CollisionShape2D = $Range/CollisionShape2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var select_area: Area2D = $SelectArea
@onready var select_shape: CollisionShape2D = $SelectArea/CollisionShape2D


var bullet_scene: PackedScene = null
var muzzles: Array[Marker2D] = []

var damage: int = 6
var range_radius: float = 150.0
var shoot_interval: float = 0.65

var target: Enemy = null
var in_range: Array[Enemy] = []
var range_preview: Line2D = null

func _ready() -> void:
	_wire_select_area()
	range_area.monitoring = true
	range_area.monitorable = true
	range_area.collision_layer = 0
	_set_range_mask()

	if not range_area.area_entered.is_connected(_on_area_entered):
		range_area.area_entered.connect(_on_area_entered)
	if not range_area.area_exited.is_connected(_on_area_exited):
		range_area.area_exited.connect(_on_area_exited)

	if select_area and not select_area.input_event.is_connected(_on_select_area_input):
		select_area.input_event.connect(_on_select_area_input)

	_apply_level()

	shoot_timer.wait_time = shoot_interval
	if not shoot_timer.timeout.is_connected(_on_shoot):
		shoot_timer.timeout.connect(_on_shoot)
	shoot_timer.autostart = true
	shoot_timer.start()

	z_index = 50
	if sprite_base: sprite_base.z_index = 50
	if sprite_top:  sprite_top.z_index  = 51   # ทับชั้นฐานเล็กน้อย

func _process(_d: float) -> void:
	if target == null or not is_instance_valid(target):
		_pick_target()
	elif not can_target_flying and target.is_in_group("flying_enemies"):
		_pick_target()
		
func _wire_select_area() -> void:
	# ทำให้ SelectArea ถูก pick ได้แน่นอน
	if select_area:
		select_area.input_pickable = true
		select_area.monitoring = true      # ไม่จำเป็นสำหรับ input_event แต่เปิดไว้ปลอดภัย
		select_area.monitorable = true
		# ชั้นชนไม่สำคัญกับ input_event แต่ตั้งค่ามาตรฐานไว้กันพลาด
		select_area.collision_layer = 1
		select_area.collision_mask = 0
		if select_shape:
			select_shape.disabled = false
		# กันต่อซ้ำ
		if not select_area.input_event.is_connected(_on_select_area_input):
			select_area.input_event.connect(_on_select_area_input)

func _on_select_area_input(_vp, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var menu := get_tree().get_first_node_in_group("floating_tower_menu")
		if menu:
			menu.call("open_for", self)


# ----- level/apply -----
func _apply_level() -> void:
	var lv: int = clamp(current_level, 1, 3)
	var cfg: Dictionary = LEVELS[lv]

	damage = int(cfg["damage"])
	range_radius = float(cfg["range"])
	shoot_interval = float(cfg["interval"])
	if cfg.has("bullet"):
		bullet_scene = cfg["bullet"]

	muzzles.clear()
	if cfg.has("muzzles"):
		for name_obj in cfg["muzzles"]:
			var mname: String = String(name_obj)
			var m: Marker2D = get_node_or_null(mname) as Marker2D
			if m:
				muzzles.append(m)

	var cs: CircleShape2D = range_shape.shape as CircleShape2D
	if cs:
		cs.radius = range_radius
	shoot_timer.wait_time = shoot_interval

	if sprite_base and sprite_base.sprite_frames and cfg.has("anim"):
		var an := String(cfg["anim"])
		if sprite_base.sprite_frames.has_animation(an):
			sprite_base.play(an)
	if sprite_top and sprite_top.sprite_frames and cfg.has("anim"):
		var an := String(cfg["anim"])
		if sprite_top.sprite_frames.has_animation(an):
			sprite_top.play(an)

	_set_range_mask()

func get_upgrade_cost() -> int:
	if current_level >= 3: return 0
	return int((LEVELS[current_level + 1] as Dictionary)["cost"])

func upgrade() -> bool:
	if current_level >= 3: return false
	current_level += 1
	_apply_level()
	return true

func _set_range_mask() -> void:
	range_area.collision_mask = 0
	range_area.set_collision_mask_value(1, true)
	if can_target_flying:
		range_area.set_collision_mask_value(2, true)

# ----- show/hide range (optional) -----
func show_range(enabled: bool) -> void:
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
		range_area.add_child(range_preview)
	else:
		if range_preview != null and is_instance_valid(range_preview):
			range_preview.queue_free()
		range_preview = null

# ----- target & fire -----
func _on_area_entered(a: Area2D) -> void:
	var p: Node = a.get_parent()
	if p != null and p.is_in_group("enemies"):
		if not can_target_flying and p.is_in_group("flying_enemies"):
			return
		var e: Enemy = p as Enemy
		if e != null and not in_range.has(e):
			in_range.append(e)
			if target == null:
				_pick_target()

func _on_area_exited(a: Area2D) -> void:
	var p: Node = a.get_parent()
	if p != null and p is Enemy:
		var e: Enemy = p as Enemy
		in_range.erase(e)
		if target == e:
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
	if bullet_scene == null:
		return

	if muzzles.is_empty():
		_spawn_bullet(global_position, target.global_position)
	else:
		for m in muzzles:
			if m and is_instance_valid(m):
				_spawn_bullet(m.global_position, target.global_position)

func _spawn_bullet(pos: Vector2, tgt: Vector2) -> void:
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	var b: Area2D = bullet_scene.instantiate() as Area2D
	parent.add_child(b)
	b.z_index = 300
	b.global_position = pos
	b.look_at(tgt)
	if b.has_method("set_data"):
		b.call("set_data", (tgt - pos).normalized(), damage)

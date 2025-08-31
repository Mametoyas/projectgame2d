extends Node2D

@export var current_level: int = 1        # 1..3
@export var can_target_flying: bool = false
@export var bullet_scene: PackedScene

const LEVELS: Array = [
	{}, # ไม่ใช้
	{
		"damage": 22, "range": 150.0, "interval": 0.9,
		"anim": "lv1_idle", "cost": 0,
		"bullet": preload("res://tower_use/aoe tower/bomb_bullet.tscn"),
		"muzzles": ["MuzzleLv1"]
	},
	{
		"damage": 32, "range": 180.0, "interval": 0.8,
		"anim": "lv2_idle", "cost": 70,
		"bullet": preload("res://tower_use/aoe tower/bomb_bullet.tscn"),
		"muzzles": ["MuzzleLv1"]
	},
	{
		"damage": 45, "range": 210.0, "interval": 0.7,
		"anim": "lv3_idle", "cost": 110,
		"bullet": preload("res://tower_use/aoe tower/bomb_bullet.tscn"),
		"muzzles": ["MuzzleLv1"]
	}
]

@onready var sprite_base: AnimatedSprite2D = $SpriteBase
@onready var sprite_top: AnimatedSprite2D  = $SpriteTop
@onready var range_area: Area2D            = $Range
@onready var range_shape: CollisionShape2D = $Range/CollisionShape2D
@onready var shoot_timer: Timer            = $ShootTimer
@onready var footprint: Area2D             = $BuildFootprint
@onready var select_area: Area2D           = $SelectArea

var muzzles: Array[Marker2D] = []

var damage: int = 10
var range_radius: float = 600.0
var shoot_interval: float = 0.6

var target: Enemy = null
var in_range: Array[Enemy] = []

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
	

	if select_area:
		select_area.input_pickable = true
		select_area.collision_mask = 0
		select_area.collision_layer = 1
		select_area.set_collision_layer_value(1, true)
		if not select_area.input_event.is_connected(_on_select_area_input):
			select_area.input_event.connect(_on_select_area_input)

	_apply_level()

	shoot_timer.wait_time = shoot_interval
	if not shoot_timer.timeout.is_connected(_on_shoot):
		shoot_timer.timeout.connect(_on_shoot)
	shoot_timer.autostart = true
	shoot_timer.start()

	z_index = 50
	if sprite_base: sprite_base.z_index = 50
	if sprite_top:  sprite_top.z_index  = 51

func _process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_pick_target()
	elif not can_target_flying and target.is_in_group("flying_enemies"):
		_pick_target()

func _on_select_area_input(_vp, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var menu := get_tree().get_first_node_in_group("floating_tower_menu")
		if menu != null and menu.has_method("open_for"):
			menu.call("open_for", self)

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
		for mname_obj in cfg["muzzles"]:
			var mname: String = String(mname_obj)
			var m: Marker2D = get_node_or_null(mname) as Marker2D
			if m:
				muzzles.append(m)

	var cs: CircleShape2D = range_shape.shape as CircleShape2D
	if cs:
		cs.radius = range_radius

	shoot_timer.wait_time = shoot_interval

	if cfg.has("anim"):
		var anim_name: String = String(cfg["anim"])
		if sprite_base and sprite_base.sprite_frames and sprite_base.sprite_frames.has_animation(anim_name):
			sprite_base.play(anim_name)
		if sprite_top and sprite_top.sprite_frames and sprite_top.sprite_frames.has_animation(anim_name):
			sprite_top.play(anim_name)

	_set_range_mask()
	print("[TOWER] apply lv=", lv, " dmg=", damage, " range=", range_radius, " interval=", shoot_interval, " muzzles=", muzzles.size())

func get_upgrade_cost() -> int:
	if current_level >= 3:
		return 0
	var next_cfg: Dictionary = LEVELS[current_level + 1]
	var c: int = int(next_cfg["cost"])
	print("[TOWER] get_upgrade_cost lv=", current_level, " -> ", c)
	return c

func upgrade() -> bool:
	if current_level >= 3:
		print("[TOWER] upgrade blocked: max level")
		return false
	current_level += 1
	print("[TOWER] upgrade -> lv=", current_level)
	_apply_level()
	return true

func _set_range_mask() -> void:
	range_area.collision_mask = 0
	range_area.set_collision_mask_value(1, true)
	if can_target_flying:
		range_area.set_collision_mask_value(2, true)

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

		var pts: PackedVector2Array = PackedVector2Array()
		for i in range(64):
			var ang: float = TAU * float(i) / 64.0
			pts.append(Vector2(cos(ang), sin(ang)) * range_radius)
		range_preview.points = pts

		var parent_node: Node = self
		if range_area != null:
			parent_node = range_area
		parent_node.add_child(range_preview)
	else:
		if range_preview != null and is_instance_valid(range_preview):
			range_preview.queue_free()
		range_preview = null

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
			_spawn_bullet(global_position)
		else:
			for m in muzzles:
				if m and is_instance_valid(m):
					_spawn_bullet(m.global_position)
	else:
		target.apply_damage(damage)

func _spawn_bullet(pos: Vector2) -> void:
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	var b: Area2D = bullet_scene.instantiate() as Area2D
	parent.add_child(b)
	b.z_index = 300
	b.global_position = pos
	b.look_at(target.global_position)
	b.set("damage", damage)
	b.set("dir", (target.global_position - pos).normalized())

func get_effective_range_radius() -> float:
	var cs: CircleShape2D = range_shape.shape as CircleShape2D
	if cs == null:
		return range_radius
	var r: float = cs.radius
	var sx: float = abs(range_area.global_scale.x)
	var sy: float = abs(range_area.global_scale.y)
	var s: float = maxf(sx, sy)
	if s <= 0.0:
		s = 1.0
	return r * s

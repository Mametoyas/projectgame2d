extends Node

@onready var ui: Control = $"../UI/BuildUI"

var pending_scene: PackedScene = null
var pending_cost: int = 0
var ghost: Node2D = null
var can_place: bool = false

var preview_line: Line2D = null   # วงรัศมีพรีวิว

func _ready() -> void:
	ui.pick_tower.connect(_on_pick_tower)
	ui.cancel_place.connect(_cancel_place)

func _process(_delta: float) -> void:
	if ghost:
		var mp := get_viewport().get_mouse_position()
		ghost.global_position = mp
		can_place = true  # ตอนนี้วางได้ทุกที่ (ยังไม่ทำแมพ)
		if can_place:
			_set_ghost_tint(Color(0, 1, 0, 0.6))
		else:
			_set_ghost_tint(Color(1, 0, 0, 0.6))

func _unhandled_input(event: InputEvent) -> void:
	if ghost == null:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_place()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_place()
		elif event.button_index == MOUSE_BUTTON_LEFT and can_place:
			_place_now()

func _on_pick_tower(scene: PackedScene, cost: int) -> void:
	pending_scene = scene
	pending_cost = cost
	_make_ghost()

func _make_ghost() -> void:
	_free_ghost()
	if pending_scene == null: return

	ghost = pending_scene.instantiate() as Node2D
	if ghost == null: return

	# ปิดการทำงานภายใน ghost
	var shoot_timer := ghost.get_node_or_null("ShootTimer") as Timer
	if shoot_timer: shoot_timer.stop()
	var range_area := ghost.get_node_or_null("Range") as Area2D
	if range_area:
		range_area.monitoring = false
		range_area.monitorable = false

	# อ่าน "ระยะจริง" ของป้อมจากซีน (รองรับทั้งใส่ใน Shape และ export var)
	var radius := _compute_tower_radius(ghost)
	_show_range_preview(radius)

	_set_ghost_tint(Color(1, 1, 1, 0.6))
	get_tree().current_scene.add_child(ghost)

func _compute_tower_radius(tower: Node) -> float:
	# 1) จาก CollisionShape ของ Range (แม่นสุด)
	var shape: CollisionShape2D = tower.get_node_or_null("Range/CollisionShape2D") as CollisionShape2D
	if shape and shape.shape is CircleShape2D:
		var r: float = (shape.shape as CircleShape2D).radius
		if r > 0.0:
			var sx: float = abs(tower.global_scale.x)
			var sy: float = abs(tower.global_scale.y)
			var s: float = max(1.0, max(sx, sy))
			return r * s

	# 2) จาก export var 'range_radius'
	if tower.has_variable("range_radius"):
		var r2: float = float(tower.get("range_radius"))
		if r2 > 0.0:
			var sx2: float = abs(tower.global_scale.x)
			var sy2: float = abs(tower.global_scale.y)
			var s2: float = max(1.0, max(sx2, sy2))
			return r2 * s2

	# 3) จากเมธอดช่วย (ถ้ามี)
	if tower.has_method("get_range_radius"):
		var r3: float = float(tower.call("get_range_radius"))
		if r3 > 0.0:
			var sx3: float = abs(tower.global_scale.x)
			var sy3: float = abs(tower.global_scale.y)
			var s3: float = max(1.0, max(sx3, sy3))
			return r3 * s3

	return 0.0


func _show_range_preview(radius: float) -> void:
	_clear_range_preview()
	if ghost == null or radius <= 0.0:
		return

	preview_line = Line2D.new()
	preview_line.width = 2.0
	preview_line.default_color = Color(0, 1, 0, 0.5)
	preview_line.closed = true
	preview_line.z_index = 0  # กัน error p_z >= CANVAS_ITEM_Z_MAX

	var pts: PackedVector2Array = PackedVector2Array()
	var segs: int = 64
	for i in segs:
		var idx: int = i
		var ang: float = TAU * float(idx) / float(segs)
		pts.append(Vector2(cos(ang), sin(ang)) * radius)
	preview_line.points = pts

	ghost.add_child(preview_line)


func _clear_range_preview() -> void:
	if preview_line and is_instance_valid(preview_line):
		preview_line.queue_free()
	preview_line = null

func _set_ghost_tint(col: Color) -> void:
	if ghost == null: return
	if ghost is CanvasItem:
		(ghost as CanvasItem).modulate = col
	for child in ghost.get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate = col

func _place_now() -> void:
	if pending_scene == null or ghost == null: return
	if not ui.spend_money(pending_cost): return

	var t := pending_scene.instantiate() as Node2D
	if t == null: return
	t.global_position = ghost.global_position
	get_tree().current_scene.add_child(t)
	t.add_to_group("towers")

	# เปิดส่วนที่ปิดตอน ghost
	var range_area := t.get_node_or_null("Range") as Area2D
	if range_area:
		range_area.monitoring = true
		range_area.monitorable = true
	var timer := t.get_node_or_null("ShootTimer") as Timer
	if timer:
		timer.start()

	_cancel_place()

func _cancel_place() -> void:
	pending_scene = null
	pending_cost = 0
	_free_ghost()

func _free_ghost() -> void:
	if ghost and is_instance_valid(ghost):
		ghost.queue_free()
	ghost = null
	preview_line = null

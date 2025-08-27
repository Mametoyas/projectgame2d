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
		var mp: Vector2 = get_viewport().get_mouse_position()
		ghost.global_position = mp
		# ตอนนี้ให้วางได้ทุกที่ (ยังไม่ทำกฎแมพ)
		can_place = true
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
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_place()
		elif mb.button_index == MOUSE_BUTTON_LEFT and can_place:
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
	var shoot_timer: Timer = ghost.get_node_or_null("ShootTimer") as Timer
	if shoot_timer: shoot_timer.stop()
	var range_area: Area2D = ghost.get_node_or_null("Range") as Area2D
	if range_area:
		range_area.monitoring = false
		range_area.monitorable = false

	# >>> ใช้ฟังก์ชันเดียวกับของจริง
	var radius: float = 0.0
	if ghost.has_method("get_effective_range_radius"):
		radius = float(ghost.call("get_effective_range_radius"))
	else:
		# fallback (เผื่อยังไม่ได้ใส่ฟังก์ชันใน tower.gd)
		var cs: CollisionShape2D = range_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if cs and cs.shape is CircleShape2D:
			var base: float = (cs.shape as CircleShape2D).radius
			var s: float = max(abs(range_area.global_scale.x), abs(range_area.global_scale.y))
			radius = base * (s if s > 0.0 else 1.0)

	_show_range_preview(range_area, radius)

	_set_ghost_tint(Color(1, 1, 1, 0.6))
	get_tree().current_scene.add_child(ghost)


# ===== แสดง/คำนวณรัศมีจริง =====
func _show_range_preview(range_area: Area2D, radius: float) -> void:
	_clear_range_preview()

	if ghost == null or range_area == null or radius <= 0.0:
		return

	preview_line = Line2D.new()
	preview_line.width = 2.0
	preview_line.default_color = Color(0, 1, 0, 0.5)
	preview_line.closed = true
	preview_line.z_index = 0  # กันปัญหา z เกิน

	var pts: PackedVector2Array = PackedVector2Array()
	var segs: int = 64
	for i in segs:
		var ang: float = TAU * float(i) / float(segs)
		pts.append(Vector2(cos(ang), sin(ang)) * radius)
	preview_line.points = pts

	# ผูกไว้กับ Range เพื่อให้ตรงศูนย์กลาง/สเกล/ออฟเซ็ต
	range_area.add_child(preview_line)

func _clear_range_preview() -> void:
	if preview_line and is_instance_valid(preview_line):
		preview_line.queue_free()
	preview_line = null

# ===== ยูทิล =====
func _set_ghost_tint(col: Color) -> void:
	if ghost == null:
		return
	if ghost is CanvasItem:
		(ghost as CanvasItem).modulate = col
	for child in ghost.get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate = col

# ===== วางป้อมจริง =====
func _place_now() -> void:
	if pending_scene == null or ghost == null:
		return
	if not ui.spend_money(pending_cost):
		return

	var t: Node2D = pending_scene.instantiate() as Node2D
	if t == null:
		return
	t.global_position = ghost.global_position
	get_tree().current_scene.add_child(t)
	t.add_to_group("towers")

	# เปิดส่วนที่ปิดตอน ghost
	var range_area: Area2D = t.get_node_or_null("Range") as Area2D
	if range_area:
		range_area.monitoring = true
		range_area.monitorable = true
	var timer: Timer = t.get_node_or_null("ShootTimer") as Timer
	if timer:
		timer.start()

	_cancel_place()

func _cancel_place() -> void:
	pending_scene = null
	pending_cost = 0
	_free_ghost()

func _free_ghost() -> void:
	_clear_range_preview()
	if ghost and is_instance_valid(ghost):
		ghost.queue_free()
	ghost = null

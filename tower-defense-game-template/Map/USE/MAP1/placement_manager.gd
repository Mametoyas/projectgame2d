extends Node
#class_name PlacementManager

@onready var ui: BuildUI = null

var pending_scene: PackedScene = null
var pending_cost: int = 0

var ghost: Node2D = null
var can_place: bool = false

func _ready() -> void:
	# หา BuildUI แบบยืดหยุ่น: ถ้ามี HUD ก็เข้า "HUD/BuildUI", ถ้าไม่มีให้ลอง "BuildUI" ตรงราก
	var root := get_tree().current_scene
	if root:
		ui = root.get_node_or_null("HUD/BuildUI") as BuildUI
		if ui == null:
			ui = root.get_node_or_null("BuildUI") as BuildUI

	# ต่อสัญญาณเมื่อพบ ui
	if ui:
		if not ui.pick_tower.is_connected(_on_pick_tower):
			ui.pick_tower.connect(_on_pick_tower)
		if not ui.cancel_place.is_connected(_cancel_place):
			ui.cancel_place.connect(_cancel_place)

func _process(_delta: float) -> void:
	if ghost:
		ghost.global_position = get_viewport().get_mouse_position()
		can_place = true
		_set_ghost_tint(Color(0, 1, 0, 0.6))

func _unhandled_input(event: InputEvent) -> void:
	if ghost == null:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_place()
	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_place()
		elif mb.button_index == MOUSE_BUTTON_LEFT and can_place:
			_place_now()

# ---------- signals ----------
func _on_pick_tower(scene: PackedScene, cost: int) -> void:
	pending_scene = scene
	pending_cost = cost
	_make_ghost()

# ---------- ghost ----------
func _make_ghost() -> void:
	_free_ghost()
	if pending_scene == null:
		return
	ghost = pending_scene.instantiate() as Node2D
	if ghost == null:
		return

	# ปิดระบบในโหมด ghost
	var timer := ghost.get_node_or_null("ShootTimer") as Timer
	if timer: timer.stop()
	var range_area := ghost.get_node_or_null("Range") as Area2D
	if range_area:
		range_area.monitoring = false
		range_area.monitorable = false
	if ghost.has_method("show_range"):
		ghost.call("show_range", true)

	_set_ghost_tint(Color(1, 1, 1, 0.6))
	get_tree().current_scene.add_child(ghost)

func _set_ghost_tint(col: Color) -> void:
	if ghost == null: return
	if ghost is CanvasItem:
		(ghost as CanvasItem).modulate = col
	for c in ghost.get_children():
		if c is CanvasItem:
			(c as CanvasItem).modulate = col

# ---------- place ----------
func _place_now() -> void:
	if pending_scene == null or ghost == null:
		return
	if ui == null:          # ยังไม่มี UI ก็กันไว้ไม่ให้ลบเงิน
		return
	if not ui.spend_money(pending_cost):
		return

	var t := pending_scene.instantiate() as Node2D
	if t == null:
		return
	t.global_position = ghost.global_position
	get_tree().current_scene.add_child(t)
	t.add_to_group("towers")

	# เปิดระบบกลับ
	var range_area := t.get_node_or_null("Range") as Area2D
	if range_area:
		range_area.monitoring = true
		range_area.monitorable = true
	var timer := t.get_node_or_null("ShootTimer") as Timer
	if timer:
		timer.start()
	if t.has_method("show_range"):
		t.call("show_range", false)

	_cancel_place()

func _cancel_place() -> void:
	pending_scene = null
	pending_cost = 0
	_free_ghost()

func _free_ghost() -> void:
	if ghost:
		if ghost.has_method("show_range"):
			ghost.call("show_range", false)
		if is_instance_valid(ghost):
			ghost.queue_free()
	ghost = null

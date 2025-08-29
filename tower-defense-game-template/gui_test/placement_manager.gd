extends Node

@onready var ui: Control = $"../UI/BuildUI"

var pending_scene: PackedScene = null
var pending_cost: int = 0
var ghost: Node2D = null
var can_place: bool = false

func _ready() -> void:
	ui.pick_tower.connect(_on_pick_tower)
	ui.cancel_place.connect(_cancel_place)

func _process(_delta: float) -> void:
	if ghost:
		var mp: Vector2 = get_viewport().get_mouse_position()
		ghost.global_position = mp
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
	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
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
	if pending_scene == null:
		return

	ghost = pending_scene.instantiate() as Node2D
	if ghost == null:
		return

	# ปิดระบบของ ghost
	var shoot_timer := ghost.get_node_or_null("ShootTimer") as Timer
	if shoot_timer:
		shoot_timer.stop()
	var range_area := ghost.get_node_or_null("Range") as Area2D
	if range_area:
		range_area.monitoring = false
		range_area.monitorable = false

	# โชว์วงรัศมี ghost
	if ghost.has_method("show_range"):
		ghost.call("show_range", true)

	_set_ghost_tint(Color(1, 1, 1, 0.6))
	get_tree().current_scene.add_child(ghost)

func _place_now() -> void:
	if pending_scene == null or ghost == null:
		return
	if not ui.spend_money(pending_cost):
		return

	var t := pending_scene.instantiate() as Node2D
	if t == null:
		return

	t.global_position = ghost.global_position
	get_tree().current_scene.add_child(t)
	t.add_to_group("towers")

	# เปิดระบบที่ปิด
	var range_area := t.get_node_or_null("Range") as Area2D
	if range_area:
		range_area.monitoring = true
		range_area.monitorable = true
	var timer := t.get_node_or_null("ShootTimer") as Timer
	if timer:
		timer.start()

	# ปิดวงรัศมีของป้อมจริง
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

func _set_ghost_tint(col: Color) -> void:
	if ghost == null:
		return
	if ghost is CanvasItem:
		(ghost as CanvasItem).modulate = col
	for child in ghost.get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate = col

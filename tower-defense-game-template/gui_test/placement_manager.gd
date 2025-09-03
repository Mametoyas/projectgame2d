extends Node
class_name PlacementManager

@onready var ui: BuildUI = $"../BuildUI"

var pending_scene: PackedScene = null
var pending_cost: int = 0

var ghost: Node2D = null
var can_place: bool = false

func _ready() -> void:
	if ui != null:
		if not ui.pick_tower.is_connected(_on_pick_tower):
			ui.pick_tower.connect(_on_pick_tower)
		if not ui.cancel_place.is_connected(_cancel_place):
			ui.cancel_place.connect(_cancel_place)

func _process(_delta: float) -> void:
	if ghost:
		# ได้พิกัดโลกของเมาส์แบบตรง ๆ จาก Node2D
		var mp: Vector2 = ghost.get_global_mouse_position()
		ghost.global_position = mp

		can_place = _check_place_valid(ghost)
		_set_ghost_tint( Color(0, 1, 0, 0.6) if can_place else Color(1, 0, 0, 0.6) )



func _unhandled_input(event: InputEvent) -> void:
	if ghost == null:
		return
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_cancel_place()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_place()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if can_place:
				_place_now()

# ============= signals =============
func _on_pick_tower(scene: PackedScene, cost: int) -> void:
	pending_scene = scene
	pending_cost = cost
	_make_ghost()

# ============= ghost mode =============
func _make_ghost() -> void:
	_free_ghost()
	if pending_scene == null:
		return

	ghost = pending_scene.instantiate() as Node2D
	if ghost == null:
		return

	var timer := ghost.get_node_or_null("ShootTimer") as Timer
	if timer != null:
		timer.stop()

	var range_area := ghost.get_node_or_null("Range") as Area2D
	if range_area != null:
		range_area.monitoring = false
		range_area.monitorable = false

	# ปิด footprint ของโกสต์
	var fp := ghost.get_node_or_null("BuildFootprint") as Area2D
	if fp != null:
		fp.monitoring = false
		fp.collision_layer = 0

	if ghost.has_method("show_range"):
		ghost.call("show_range", true)

	_set_ghost_tint(Color(1, 1, 1, 0.6))
	get_tree().current_scene.add_child(ghost)


func _set_ghost_tint(col: Color) -> void:
	if ghost == null:
		return
	if ghost is CanvasItem:
		(ghost as CanvasItem).modulate = col
	for c in ghost.get_children():
		if c is CanvasItem:
			(c as CanvasItem).modulate = col

# ============= place =============
func _place_now() -> void:
	if pending_scene == null:
		return
	if ghost == null:
		return
	if ui == null:
		return
	if not ui.spend_money(pending_cost):
		return

	var tower := pending_scene.instantiate() as Node2D
	if tower == null:
		return

	tower.global_position = ghost.global_position
	get_tree().current_scene.add_child(tower)
	tower.add_to_group("towers")

	# เปิดระบบที่ปิดตอนโกสต์
	var range_area := tower.get_node_or_null("Range") as Area2D
	if range_area != null:
		range_area.monitoring = true
		range_area.monitorable = true

	var timer := tower.get_node_or_null("ShootTimer") as Timer
	if timer != null:
		timer.start()

	# เปิด footprint ให้ชนเลเยอร์ 9 อีกครั้ง และไม่ตรวจมาสก์ใด ๆ
	var fp2 := tower.get_node_or_null("BuildFootprint") as Area2D
	if fp2 != null:
		fp2.monitoring = true
		fp2.collision_layer = 0
		fp2.set_collision_layer_value(9, true)
		fp2.collision_mask = 0

	if tower.has_method("show_range"):
		tower.call("show_range", false)
	_update_tower_z_index(tower)
	_cancel_place()


# ============= cancel / cleanup =============
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

# ============= ตรวจพื้นที่ห้ามวาง =============
func _check_place_valid(tower: Node2D) -> bool:
	# หาโหนดรูปทรงของ footprint
	var shape_node: Node = tower.get_node_or_null("BuildFootprint/CollisionShape2D")
	if shape_node == null:
		shape_node = tower.get_node_or_null("BuildFootprint/CollisionPolygon2D")
	if shape_node == null:
		return true

	var space: PhysicsDirectSpaceState2D = get_viewport().world_2d.direct_space_state
	var q: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var xf: Transform2D = (shape_node as Node2D).global_transform

	if shape_node is CollisionShape2D:
		var s: Shape2D = (shape_node as CollisionShape2D).shape
		if s == null:
			return true
		q.shape = s
		q.transform = xf
	elif shape_node is CollisionPolygon2D:
		var poly: PackedVector2Array = (shape_node as CollisionPolygon2D).polygon
		if poly.is_empty():
			return true
		var convexes: Array[PackedVector2Array] = Geometry2D.decompose_polygon_in_convex(poly)
		if convexes.is_empty():
			return true
		var convex: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
		convex.set_points(convexes[0])
		q.shape = convex
		q.transform = xf
	else:
		return true

	# คิวรีเฉพาะ Area ในเลเยอร์ 8 no_build และ 9 tower_footprint
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = (1 << 7) | (1 << 8)  # ช่องที่ 8 และ 9

	# กันชน footprint ของโกสต์เอง
	var fp_area: Area2D = tower.get_node_or_null("BuildFootprint") as Area2D
	if fp_area != null:
		q.exclude = [fp_area.get_rid()]

	var results: Array = space.intersect_shape(q, 16)
	var i := 0
	while i < results.size():
		var d: Dictionary = results[i]
		var n: Node = d.get("collider")
		if n != null:
			if n.is_in_group("no_build"):
				return false
			if n.is_in_group("tower_footprint"):
				return false
		i += 1

	return true

# ============= tower z_index sorting ============
func _update_tower_z_index(tower: Node2D) -> void:
	# Higher Y = higher z_index (drawn in front)
	tower.z_index = int(tower.global_position.y)

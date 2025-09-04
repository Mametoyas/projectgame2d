extends Panel
class_name FloatingTowerMenu

@export var menu_offset: Vector2 = Vector2(60, -48)

@onready var upgrade_btn: Button = $UpgradeButton
@onready var toggle_btn:  Button = $ToggleRangeButton
@onready var sell_btn:    Button = $SellButton

const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")

var tower: Node2D = null
var follow := false

func _ready() -> void:
	visible = false
	upgrade_btn.pressed.connect(_on_upgrade)
	toggle_btn.pressed.connect(_on_toggle_range)
	sell_btn.pressed.connect(_on_sell)
	print("Menu ready")

func open_for(t: Node2D) -> void:
	tower = t
	visible = true
	follow = true
	_update_texts()
	_update_position()

func close() -> void:
	visible = false
	follow = false
	tower = null

func _process(_dt: float) -> void:
	if not follow: return
	if tower == null or not is_instance_valid(tower):
		close()
		return
	_update_position()

func _update_position() -> void:
	if tower == null:
		return
	var xf: Transform2D = get_viewport().get_canvas_transform()
	var screen_pos: Vector2 = xf * tower.global_position
	position = screen_pos + menu_offset



func _update_texts() -> void:
	if tower == null: return
	var cost := 0
	if tower.has_method("get_upgrade_cost"):
		cost = int(tower.call("get_upgrade_cost"))
	if cost > 0:
		upgrade_btn.text = "Upgrade (%d)" % cost
		upgrade_btn.disabled = false
	else:
		upgrade_btn.text = "Max Level"
		upgrade_btn.disabled = true

# ---------- helper: หา BuildUI ให้เจอทั้งสองกรณี ----------
func _find_build_ui() -> Node:
	var root := get_tree().current_scene
	if root == null: 
		return null
	var ui := root.get_node_or_null("HUD/BuildUI")
	if ui == null:
		ui = root.get_node_or_null("BuildUI")  # เผื่อรัน HUD.tscn ตรง ๆ
	return ui

func _on_upgrade() -> void:
	if tower == null:
		return

	var ui := _find_build_ui()
	if ui == null:
		print("[UP] HUD/BuildUI not found")
		return

	var cost := int(tower.call("get_upgrade_cost"))
	if cost <= 0:
		_update_texts()
		return

	var paid := bool(ui.call("spend_money", cost))
	if not paid:
		return

	if tower.has_method("upgrade"):
		SFX.play_ui(SND_CLICK)
		tower.call("upgrade")
	_update_texts()

func _on_toggle_range() -> void:
	if tower == null:
		return
	var showing := false
	if tower.has_method("get"):
		SFX.play_ui(SND_CLICK)
		var r = tower.get("range_preview")
		showing = (r != null and is_instance_valid(r))
	tower.call("show_range", not showing)

func _on_sell() -> void:
	if tower == null:
		return
	var ui := _find_build_ui()
	if ui != null and ui.has_method("add_money"):
		ui.call("add_money", 30)
		SFX.play_ui(SND_CLICK)
	tower.queue_free()
	close()

func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		# ถ้าคลิกนอกกรอบเมนู -> ปิด
		if not get_global_rect().has_point((e as InputEventMouseButton).position):
			close()
	elif e is InputEventKey and e.pressed and (e.keycode == KEY_ESCAPE):
		close()

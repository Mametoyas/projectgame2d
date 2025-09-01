# Base.gd
extends Node2D

@export var max_hp: int = 10                      # ชนครบ 10 ครั้งแพ้
@export_file("*.tscn") var lose_scene_path: String = "res://menu/lose_screen.tscn"

signal hp_changed(current: int, max: int)
signal base_destroyed

@onready var goal_area: Area2D = $GoalArea

var hp: int
var _dead: bool = false

func _ready() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	if goal_area and not goal_area.area_entered.is_connected(_on_goal_area_entered):
		goal_area.area_entered.connect(_on_goal_area_entered)

func _on_goal_area_entered(a: Area2D) -> void:
	if _dead:
		return
	var e := a.get_parent()
	if e and e.is_in_group("enemies"):
		apply_damage(1)
		# ฆ่าศัตรูแบบปลอดภัยในเฟรมถัดไป
		if e.has_method("die"):
			e.call_deferred("die")
		elif e.has_method("apply_damage"):
			e.call_deferred("apply_damage", 999999)
		else:
			e.call_deferred("queue_free")


func apply_damage(amount: int) -> void:
	if _dead:
		return
	hp = max(0, hp - max(0, amount))
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		_dead = true
		base_destroyed.emit()
		_go_to_lose()

func _go_to_lose() -> void:
	# ห้ามแตะสถานะฟิสิกส์ตรง ๆ ในคอลแบ็ก → ใช้ set_deferred
	if goal_area:
		goal_area.set_deferred("monitoring", false)
		goal_area.set_deferred("monitorable", false)
	set_physics_process(false)
	set_process(false)
	call_deferred("_change_to_lose")  # เปลี่ยนฉากเฟรมถัดไป

func _change_to_lose() -> void:
	if lose_scene_path == "":
		return

	# บันทึกพาธด่านปัจจุบันไว้ให้หน้าแพ้ใช้ Retry
	var cs := get_tree().current_scene
	if cs != null:
		get_tree().set_meta("last_level_path", cs.scene_file_path)

	get_tree().paused = false
	get_tree().change_scene_to_file(lose_scene_path)

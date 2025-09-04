# Base.gd
extends Node2D

@export var max_hp: int = 10                      # ชนครบ 10 ครั้งแพ้
@export_file("*.tscn") var lose_scene_path: String = "res://menu/lose_screen.tscn"

signal hp_changed(current: int, max: int)
signal base_destroyed

@onready var goal_area: Area2D = $GoalArea
@onready var hp_label: Label = $HPLabel

const SND_LOSE := preload("res://audio/monster-bite-44538.mp3")

var hp: int
var _dead: bool = false

func _ready() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	if goal_area and not goal_area.area_entered.is_connected(_on_goal_area_entered):
		goal_area.area_entered.connect(_on_goal_area_entered)
		
	_update_hp_label(hp, max_hp)
	if not hp_changed.is_connected(_update_hp_label):
		hp_changed.connect(_update_hp_label)
		
func _update_hp_label(current: int, maxhp: int) -> void:
	if hp_label:
		hp_label.text = "Base HP: %d/%d" % [current, maxhp]
		# เปลี่ยนสีเล็กน้อยตามสภาพ
		var r := float(current) / float(maxhp)
		if r <= 0.25:
			hp_label.modulate = Color(1, 0.25, 0.25)   # แดงอ่อน
		elif r <= 0.5:
			hp_label.modulate = Color(1, 0.7, 0.2)     # ส้ม
		else:
			hp_label.modulate = Color(1, 1, 1)         # ขาว

func _on_goal_area_entered(a: Area2D) -> void:
	if _dead:
		return

	var e := a.get_parent()
	if e and e.is_in_group("enemies"):
		var dmg: int = 1
		if e.is_in_group("bosses"):
			dmg = 9999   # บอสชนฐาน ดาเมจ 9999

		SFX.play_ui(SND_LOSE)
		apply_damage(dmg)

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
	StageProgress.save_unlocked(1)

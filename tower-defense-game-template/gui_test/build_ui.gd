extends Control

signal pick_tower(scene: PackedScene, cost: int)
signal cancel_place

@export var ground_tower_scene: PackedScene
@export var air_tower_scene: PackedScene
@export var ground_cost: int = 50
@export var air_cost: int = 60

@onready var money_label: Label = $MoneyLabel
@onready var ground_btn: Button = $GroundBtn
@onready var air_btn: Button    = $AirBtn
@onready var cancel_btn: Button = $CancelBtn

var money: int = 200

func _ready() -> void:
	# ปุ่มอยู่ตรงไหน → กำหนดจาก Inspector/ลากใน Editor ได้เลย ไม่ใช้ Container
	_update_money_ui()
	ground_btn.pressed.connect(func():
		if money >= ground_cost and ground_tower_scene:
			emit_signal("pick_tower", ground_tower_scene, ground_cost)
	)
	air_btn.pressed.connect(func():
		if money >= air_cost and air_tower_scene:
			emit_signal("pick_tower", air_tower_scene, air_cost)
	)
	cancel_btn.pressed.connect(func():
		emit_signal("cancel_place")
	)

func _update_money_ui() -> void:
	money_label.text = "Money: %d" % money
	ground_btn.disabled = (money < ground_cost or ground_tower_scene == null)
	air_btn.disabled    = (money < air_cost   or air_tower_scene == null)

func add_money(amount: int) -> void:
	money += amount
	_update_money_ui()

func spend_money(amount: int) -> bool:
	if money < amount: return false
	money -= amount
	_update_money_ui()
	return true

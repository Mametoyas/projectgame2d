extends HBoxContainer
class_name BuildUI

signal pick_tower(scene: PackedScene, cost: int)
signal cancel_place

@export var ground_tower_scene: PackedScene
@export var ground_cost: int = 50

@onready var money_label: Label = $"../MoneyLabel"
@onready var buy_btn: Button = $BuyTower1
@onready var cancel_btn: Button = $CancelPlace

var money: int = 200

func _ready() -> void:
	_update_money_ui()
	buy_btn.pressed.connect(func():
		if money >= ground_cost and ground_tower_scene:
			pick_tower.emit(ground_tower_scene, ground_cost)
	)
	cancel_btn.pressed.connect(func(): cancel_place.emit())

func _update_money_ui() -> void:
	if money_label:
		money_label.text = "Money: %d" % money
	buy_btn.disabled = (money < ground_cost or ground_tower_scene == null)

func add_money(amount: int) -> void:
	money += amount
	_update_money_ui()

func spend_money(amount: int) -> bool:
	if money < amount:
		print("[UI] not enough money. have=", money, " need=", amount)
		return false
	money -= amount
	_update_money_ui()
	print("[UI] spend=", amount, " remain=", money)
	return true

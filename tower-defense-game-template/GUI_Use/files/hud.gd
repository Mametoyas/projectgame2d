extends CanvasLayer
class_name HUD

signal money_changed(value: int)

@export var start_money: int = 150
@onready var money_label: Label = $MoneyLabel

var money: int

func _ready() -> void:
	money = start_money
	_update_ui()
	emit_signal("money_changed", money)
	add_to_group("hud")

func can_spend(cost: int) -> bool:
	return money >= cost

func spend(cost: int) -> bool:
	if money < cost:
		return false
	money -= cost
	_update_ui()
	emit_signal("money_changed", money)
	return true

func add_cash(amount: int) -> void:
	money += amount
	_update_ui()
	emit_signal("money_changed", money)

func _update_ui() -> void:
	if money_label:
		money_label.text = "Money: %d" % money

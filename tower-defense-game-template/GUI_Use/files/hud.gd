extends CanvasLayer
class_name HUD

@onready var money_label: Label = $MoneyLabel
@onready var build_ui: Node = $BuildUI
@onready var floating_menu: Node = $FloatingTowerMenu

var money: int = 400

func _ready() -> void:
	add_to_group("hud")
	update_money()
	#var menu = $FloatingTowerMenu
	
func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	update_money()
	return true

func add_money(amount: int) -> void:
	money += amount
	update_money()

func update_money() -> void:
	money_label.text = "Money: %d" % money

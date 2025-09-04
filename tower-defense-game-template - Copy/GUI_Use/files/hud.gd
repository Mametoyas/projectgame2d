extends CanvasLayer
class_name HUD

signal money_changed(amount: int)
const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")
@export var pause_game: String = "res://pause_menu.tscn" 
@export var main_menu: String = "res://menu/main_menu.tscn"

@onready var money_label: Label = $MoneyLabel
@onready var build_ui: Node = $BuildUI
@onready var floating_menu: Node = $FloatingTowerMenu


var money: int = 400

func _ready() -> void:
	add_to_group("hud")
	# ให้ BuildUI ฟังสัญญาณเงิน
	if build_ui and build_ui.has_method("update_money_ui") and not money_changed.is_connected(build_ui.update_money_ui):
		money_changed.connect(build_ui.update_money_ui)
	update_money()  # จะ emit ค่าปัจจุบันด้วย

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
	money_changed.emit(money)  # <<< สำคัญ: แจ้งให้ BuildUI อัปเดต


func _on_return_btn_pressed() -> void:
	get_tree().paused = true
	$Pause_menu.visible = true

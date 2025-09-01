extends HBoxContainer
class_name BuildUI

signal pick_tower(scene: PackedScene, cost: int)
signal cancel_place

@export var ground_tower_scene: PackedScene
@export var ground_cost: int = 50
@export var aoe_tower_scene: PackedScene
@export var aoe_cost: int = 60
@export var pierce_tower_scene: PackedScene
@export var pierce_cost: int = 60

@onready var money_label: Label = $"../MoneyLabel"
@onready var buy_btn: Button = $BuyTower1
@onready var buy_aoe: Button = $BuyTower2
@onready var buy_pierce: Button = $BuyTower3
@onready var cancel_btn: Button = $CancelPlace

const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")

var money: int = 400

func _ready() -> void:
	_update_money_ui()
	buy_btn.pressed.connect(func():
		if money >= ground_cost and ground_tower_scene:
			pick_tower.emit(ground_tower_scene, ground_cost)
			SFX.play_ui(SND_CLICK)
	)
	
	buy_aoe.pressed.connect(func():
		if money >= aoe_cost and aoe_tower_scene:
			pick_tower.emit(aoe_tower_scene, aoe_cost)
			SFX.play_ui(SND_CLICK)
	)
	buy_pierce.pressed.connect(func():
		if money >= pierce_cost and pierce_tower_scene:
			pick_tower.emit(pierce_tower_scene, pierce_cost)
			SFX.play_ui(SND_CLICK)
	)
	cancel_btn.pressed.connect(func(): cancel_place.emit())

func _update_money_ui() -> void:
	if money_label:
		money_label.text = "Money: %d" % money
	buy_btn.disabled = (money < ground_cost or ground_tower_scene == null)
	buy_aoe.disabled = (money < aoe_cost or aoe_tower_scene == null)
	buy_pierce.disabled = (money < pierce_cost or pierce_tower_scene == null)

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

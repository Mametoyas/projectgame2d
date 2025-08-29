extends Control
class_name BuildUI

signal pick_tower(scene: PackedScene, cost: int)
signal cancel_place()

@export var tower1_scene: PackedScene
@export var tower1_cost: int = 50

@onready var buy1: Button = $BuyTower1
@onready var cancel_btn: Button = $CancelPlace

func _ready() -> void:
	if buy1 and not buy1.pressed.is_connected(_on_buy1):
		buy1.pressed.connect(_on_buy1)
	if cancel_btn and not cancel_btn.pressed.is_connected(_on_cancel):
		cancel_btn.pressed.connect(_on_cancel)

func _on_buy1() -> void:
	emit_signal("pick_tower", tower1_scene, tower1_cost)

func _on_cancel() -> void:
	emit_signal("cancel_place")

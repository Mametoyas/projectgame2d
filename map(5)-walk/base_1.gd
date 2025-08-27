# Base.gd
extends Node2D

@export var max_hp: int = 20
signal hp_changed(current: int, max: int)
signal base_destroyed

var hp: int

func _ready():
	hp = max_hp
	emit_signal("hp_changed", hp, max_hp)

func apply_damage(amount: int) -> void:
	hp = max(hp - max(0, amount), 0)
	emit_signal("hp_changed", hp, max_hp)
	if hp <= 0:
		emit_signal("base_destroyed")
		print("Base destroyed!")

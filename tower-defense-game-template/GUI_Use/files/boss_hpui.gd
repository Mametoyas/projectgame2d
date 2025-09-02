extends Control
class_name BossHPUI

@onready var bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

func _ready() -> void:
	visible = false   # ปิดตั้งแต่เริ่ม

func show_for_boss(max_hp: int) -> void:
	bar.max_value = max_hp
	bar.value = max_hp
	label.text = "BossHP: %d / %d" % [max_hp, max_hp]
	visible = true     # โผล่เฉพาะตอนบอสออกมา

func update_hp(current: int, max_hp: int) -> void:
	bar.value = current
	label.text = "%d / %d" % [current, max_hp]

func hide_bar() -> void:
	visible = false    # หายไปเมื่อบอสตาย

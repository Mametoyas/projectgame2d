extends Resource
class_name EnemyDef

@export var scene: PackedScene         # ลากศัตรูเช่น res://enemy_sheep.tscn
@export_range(0, 999) var count := 1   # จำนวนตัวในเวฟนี้

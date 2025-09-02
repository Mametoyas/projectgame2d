extends Node
class_name BossFactory

const SCENE := preload("res://walking_enemy/enemy scritp/evil_eye_boss.tscn")

func _ready() -> void:
	add_to_group("boss_factory")

func spawn(id: String, carrier: PathFollow2D) -> Boss:
	# ไม่สน id เพราะมีบอสเดียว
	print(id)
	var b: Boss = SCENE.instantiate() as Boss
	if b and carrier:
		b.setup_with_carrier(carrier)
	return b

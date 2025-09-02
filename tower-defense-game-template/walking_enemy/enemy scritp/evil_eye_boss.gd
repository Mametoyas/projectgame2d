extends Node2D
class_name Boss

signal died(reward: int)
signal hp_changed(current: int, max_hp: int)

@export var max_hp: int = 800
@export var speed: float = 90.0
@export var armor: int = 3
@export var reward: int = 120

# โจมตีป้อม
@export var attack_range: float = 80.0       # ระยะตรวจป้อม
@export var attack_cooldown: float = 1.0     # เวลาหน่วงระหว่างทุบ

var hp: int
var alive := true
var carrier: PathFollow2D = null

var _attack_cd := 0.0
var _attacking := false
var _attack_target: Node2D = null

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	add_to_group("bosses")
	add_to_group("enemies")              # ให้ระบบกระสุน/ฐานเดิมยังทำงานกับบอส
	hp = max_hp
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
	# ไม่ต้องต่อสัญญาณ hitbox เพิ่ม — กระสุนของคุณเรียก apply_damage อยู่แล้ว

func setup_with_carrier(pf: PathFollow2D) -> void:
	carrier = pf
	global_position = pf.global_position

func _physics_process(delta: float) -> void:
	if not alive:
		return

	# เดินตามทาง (หยุดเพิ่ม progress ระหว่างกำลังตี)
	if carrier and not _attacking:
		carrier.progress += speed * delta
		global_position = carrier.global_position
	elif carrier:
		# กำลังตี → คงตำแหน่งตาม carrier ไว้เฉย ๆ
		global_position = carrier.global_position

	# คูลดาวน์การตี
	if _attack_cd > 0.0:
		_attack_cd = max(0.0, _attack_cd - delta)

	# ลองหาเป้าหมายป้อมแล้วตี
	if not _attacking and _attack_cd <= 0.0:
		_try_attack_tower()

func _try_attack_tower() -> void:
	var towers: Array[Node] = get_tree().get_nodes_in_group("towers")
	var best: Node2D = null
	var best_d2: float = INF

	for t in towers:
		var tn: Node2D = t as Node2D
		if tn != null and is_instance_valid(tn):
			var d2: float = global_position.distance_squared_to(tn.global_position)
			if d2 < attack_range * attack_range and d2 < best_d2:
				best_d2 = d2
				best = tn

	if best == null:
		return

	_attacking = true
	_attack_cd = attack_cooldown
	_attack_target = best

	print("Boss locked target: ", _attack_target.name)

	# เล่น animation "hit" ถ้ามี
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")

	# ⚡ ตีแล้วลบป้อมทันที ไม่ต้องรอ animation
	_finish_attack()



func _finish_attack() -> void:
	if _attack_target and is_instance_valid(_attack_target):
		print("Boss destroying tower: ", _attack_target.name)
		_attack_target.queue_free()
	else:
		print("Boss had no valid target")

	_attack_target = null
	_attacking = false

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")



func apply_damage(amount: int) -> void:
	if not alive:
		return
	var real: int = max(0, amount - armor)   # <— ใส่ชนิดเป็น int
	hp = max(0, hp - real)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		die()

func die() -> void:
	if not alive:
		return
	alive = false
	died.emit(reward)
	queue_free()

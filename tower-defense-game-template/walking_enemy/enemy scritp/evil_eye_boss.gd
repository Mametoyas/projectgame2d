extends Node2D
class_name Boss

signal died(reward: int)
signal hp_changed(current: int, max_hp: int)

@export var max_hp: int = 6666
@export var speed: float = 60.0
@export var armor: int = 3
@export var reward: int = 120

@export var attack_range: float = 600.0
@export var attack_cooldown: float = 0.01

var hp: int
var alive: bool = true
var carrier: PathFollow2D = null

var _attack_cd: float = 0.0
var _attacking: bool = false
var _attack_target: Node2D = null

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox

const SND_BOSS_ENTER := preload("res://BackGround_Music/Boss_appere.wav")
const SND_BOSS_HIT   := preload("res://audio/sword-slash-with-a-designed-impact-185434.mp3")

func _apply_hitbox_layers() -> void:
	if hitbox == null:
		return
	# บอสเป็น “สิ่งถูกยิง” → เปิดเฉพาะ layer, ปล่อยมาส์ก = 0 (ให้กระสุนเป็นคนตรวจ)
	hitbox.collision_layer = 0
	hitbox.collision_mask = 0
	hitbox.set_collision_layer_value(1, true) # ศัตรูดิน
	hitbox.set_collision_layer_value(2, true) # ศัตรูบิน
	hitbox.monitoring = true
	hitbox.monitorable = true

func _ready() -> void:
	add_to_group("enemies")  # สำคัญ: ให้ป้อมมองเห็นและยิงได้
	add_to_group("bosses")

	_apply_hitbox_layers()

	# ไม่ต้องต่อ area_entered จากฝั่งบอส
	# กระสุนของคุณเป็นฝ่ายตรวจและเรียก apply_damage อยู่แล้ว
	# ถ้าต่อทั้งสองฝั่งจะเสี่ยงโดนดาเมจซ้ำ

	hp = max_hp
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")

	# SFX เข้าฉาก
	SFX.play_2d(SND_BOSS_ENTER, global_position)

	# HUD: BossHPUI (เรียกแบบไม่พึ่ง type class)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_node("BossHPUI"):
		var bar := hud.get_node("BossHPUI")
		if bar and bar.has_method("show_for_boss"):
			bar.call("show_for_boss", max_hp)
		# อัปเดตเลข/แถบ
		if bar and bar.has_method("update_hp"):
			hp_changed.connect(func(cur, mx): bar.call("update_hp", cur, mx))
		# ตายแล้วซ่อน
		if bar and bar.has_method("hide_bar"):
			died.connect(func(_r): bar.call("hide_bar"))

func setup_with_carrier(pf: PathFollow2D) -> void:
	carrier = pf
	global_position = pf.global_position

func _physics_process(delta: float) -> void:
	if not alive:
		return

	# เดินตามเส้นหากไม่ได้กำลังตี
	if carrier:
		if not _attacking:
			carrier.progress += speed * delta
		global_position = carrier.global_position

	# คูลดาวน์การตี
	if _attack_cd > 0.0:
		_attack_cd = max(0.0, _attack_cd - delta)

	# หาป้อมในระยะแล้วตี
	if not _attacking and _attack_cd <= 0.0:
		_try_attack_tower()

func _try_attack_tower() -> void:
	var towers: Array[Node] = get_tree().get_nodes_in_group("towers")
	var best: Node2D = null
	var best_d2: float = INF

	for t in towers:
		if t and is_instance_valid(t):
			var d2: float = global_position.distance_squared_to((t as Node2D).global_position)
			if d2 < attack_range * attack_range and d2 < best_d2:
				best_d2 = d2
				best = t as Node2D

	if best == null:
		return

	_attacking = true
	_attack_cd = attack_cooldown
	_attack_target = best

	# เล่นแอนิเมชัน hit ให้จบก่อน แล้วค่อยลบป้อม
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")
		SFX.play_2d(SND_BOSS_HIT, global_position)
		if not sprite.animation_finished.is_connected(_finish_attack):
			sprite.animation_finished.connect(_finish_attack, CONNECT_ONE_SHOT)
	else:
		_finish_attack()

func _finish_attack() -> void:
	if _attack_target and is_instance_valid(_attack_target):
		_attack_target.queue_free()
	_attack_target = null
	_attacking = false

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")

# ====== ถูกกระสุนยิง (กระสุนเป็นฝ่ายตรวจชน) ======
func apply_damage(amount: int) -> void:
	if not alive:
		return
	var real: int = max(1, amount - armor)
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

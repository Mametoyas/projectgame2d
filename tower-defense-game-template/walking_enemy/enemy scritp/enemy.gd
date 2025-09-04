extends Node2D
class_name Enemy

signal died(reward: int)
signal reached_end

@export var rotate_along_path: bool = true

var type_id: String = "crawler"
var speed: float = 120.0
var max_hp: int = 20
var reward: int = 5
var armor: int = 0
var regen: float = 0.0
var flying: bool = false
var shield_hp: int = 0
var on_death_spawn: Dictionary = {}
var size: float = 1.0
var anim_name: String = ""

var hp: float = 0.0
var follower: PathFollow2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var bar_root: Node2D    = $HPBarRoot
@onready var bar_back: ColorRect = $HPBarRoot/Back
@onready var bar_fill: ColorRect = $HPBarRoot/Fill

@export var bar_size: Vector2 = Vector2(28, 5)

const SND_DIE := preload("res://audio/monster-death-grunt-131480.mp3")

# ======================
# ตั้งค่า Layer ให้ Hitbox ตามชนิด (บิน/ดิน)
func _apply_hitbox_layers() -> void:
	if hitbox == null:
		return
	hitbox.collision_layer = 0
	hitbox.collision_mask = 0
	if flying:
		# ศัตรูบินอยู่ Layer 2
		hitbox.set_collision_layer_value(2, true)
	else:
		# ศัตรูภาคพื้นอยู่ Layer 1
		hitbox.set_collision_layer_value(1, true)
# ======================

func setup(config: Dictionary) -> void:
	type_id   = String(config.get("type_id", type_id))
	speed     = float(config.get("speed", speed))
	max_hp    = int(config.get("hp", max_hp))
	reward    = int(config.get("reward", reward))
	armor     = int(config.get("armor", armor))
	regen     = float(config.get("regen", regen))
	flying    = bool(config.get("flying", flying))
	shield_hp = int(config.get("shield_hp", shield_hp))

	var d = config.get("on_death_spawn", {})
	if d is Dictionary:
		on_death_spawn = d
	else:
		on_death_spawn = {}

	size      = float(config.get("size", size))
	anim_name = String(config.get("anim", anim_name))
	scale     = Vector2.ONE * size

	# หลังจากรู้ค่า flying แล้ว → ตั้ง Layer ของ Hitbox
	_apply_hitbox_layers()

func _ready() -> void:
	hp = max_hp

	# ตั้งค่า HP bar
	bar_back.size = bar_size
	bar_back.color = Color(0, 0, 0, 0.75)
	bar_fill.size = bar_size - Vector2(2,2)
	bar_fill.position = Vector2(1,1)
	bar_fill.color = Color(0.2, 0.9, 0.2)
	_update_bar()

	_apply_hitbox_layers()   # กันพลาด เรียกอีกทีตอนเริ่ม
	print("Enemy:", type_id, " flying=", flying, " layer=", hitbox.collision_layer)
	if flying: add_to_group("flying_enemies")
	add_to_group("enemies")
	if hitbox:
		hitbox.area_entered.connect(_on_area_entered)
	if anim_name != "" and anim and anim.sprite_frames and anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)

func _process(delta: float) -> void:
	if follower == null: return
	follower.progress += speed * delta
	global_position = follower.global_position
	if rotate_along_path:
		rotation = follower.rotation
	if regen > 0.0 and hp > 0.0:
		hp = min(hp + regen * delta, float(max_hp))
		_update_bar()
	if follower.progress_ratio >= 1.0:
		reached_end.emit()
		call_deferred("queue_free")


func apply_damage(amount: int) -> void:
	if amount <= 0: return
	var dmg: int = max(amount - armor, 1)
	if shield_hp > 0:
		var absorbed: int = min(dmg, shield_hp)
		shield_hp -= absorbed
		dmg -= absorbed
		# อัปเดตแถบเลือด/สีทันที เผื่อโล่เพิ่งหมด
		_update_bar()
		if dmg <= 0:
			return
	hp -= float(dmg)
	_update_bar()
	if hp <= 0.0:
		SFX.play_2d(SND_DIE, global_position)
		_spawn_children_if_any()
		died.emit(reward)
		call_deferred("queue_free")


func _update_bar() -> void:
	var ratio: float = clamp(hp / float(max_hp), 0.0, 1.0)
	bar_fill.size.x = (bar_size.x - 2.0) * ratio

	# สีของหลอด: มีโล่ = ขาว, โล่หมด = เขียว
	if shield_hp > 0:
		bar_fill.color = Color(1, 1, 1, 1)         # ขาว
	else:
		bar_fill.color = Color(0.2, 0.9, 0.2, 1)   # เขียว


func _on_area_entered(a: Area2D) -> void:
	if a.has_method("get_damage"):
		apply_damage(int(a.get_damage()))

func _spawn_children_if_any() -> void:
	if on_death_spawn.is_empty():
		return
	var t: String = String(on_death_spawn.get("type_id", ""))
	var c: int = int(on_death_spawn.get("count", 0))
	var s: float = float(on_death_spawn.get("spread", 8.0))
	if t == "" or c <= 0:
		return

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null: return
	var factory := tree.get_first_node_in_group("enemy_factory")
	if factory == null or not factory.has_method("spawn"):
		return

	for i in c:
		var path2d := follower.get_parent() as Path2D
		if path2d == null: break
		var f: PathFollow2D = follower.duplicate() as PathFollow2D
		f.progress = max(0.0, follower.progress - 10.0)
		f.h_offset = randf_range(-s, s)
		f.v_offset = randf_range(-s, s)
		path2d.call_deferred("add_child", f)

		var child = factory.spawn(t, f)
		if child:
			get_parent().call_deferred("add_child", child)

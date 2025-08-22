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
var on_death_spawn: Dictionary = {}   # << สำคัญ: ให้เป็น Dictionary เสมอ
var size: float = 1.0
var anim_name: String = ""

var hp: float = 0.0
var follower: PathFollow2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hpbar: TextureProgressBar = $HPBar
@onready var hitbox: Area2D = $Hitbox

func setup(config: Dictionary) -> void:
	type_id   = String(config.get("type_id", type_id))
	speed     = float(config.get("speed", speed))
	max_hp    = int(config.get("hp", max_hp))
	reward    = int(config.get("reward", reward))
	armor     = int(config.get("armor", armor))
	regen     = float(config.get("regen", regen))
	flying    = bool(config.get("flying", flying))
	shield_hp = int(config.get("shield_hp", shield_hp))

	# ---- ตรงนี้คือส่วนแก้ ----
	var d = config.get("on_death_spawn", {})
	if d is Dictionary:
		on_death_spawn = d
	else:
		on_death_spawn = {}
	# --------------------------

	size      = float(config.get("size", size))
	anim_name = String(config.get("anim", anim_name))
	scale     = Vector2.ONE * size


func _ready() -> void:
	hp = max_hp
	if hpbar:
		hpbar.max_value = max_hp
		hpbar.value = hp
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
		if hpbar: hpbar.value = hp
	if follower.progress_ratio >= 1.0:
		reached_end.emit()
		queue_free()

func apply_damage(amount: int) -> void:
	if amount <= 0: return
	var dmg: int = max(amount - armor, 1)
	if shield_hp > 0:
		var absorbed: int = min(dmg, shield_hp)
		shield_hp -= absorbed
		dmg -= absorbed
		if dmg <= 0: return
	hp -= float(dmg)
	if hpbar: hpbar.value = max(hp, 0.0)
	if hp <= 0.0:
		_spawn_children_if_any()
		died.emit(reward)
		queue_free()

func _on_area_entered(a: Area2D) -> void:
	if a.has_method("get_damage"):
		apply_damage(int(a.get_damage()))

# ====== ไม่อ้างชื่อคลาส EnemyFactory อีกต่อไป ======
func _spawn_children_if_any() -> void:
	if on_death_spawn.is_empty():
		return
	var t: String = String(on_death_spawn.get("type_id", ""))
	var c: int = int(on_death_spawn.get("count", 0))
	var s: float = float(on_death_spawn.get("spread", 8.0))
	if t == "" or c <= 0:
		return

	# หาโรงงานผ่าน group แทน (ไม่ต้องรู้จัก class)
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
		path2d.add_child(f)
		var child = factory.spawn(t, f)   # เรียกด้วย method ปกติ
		if child:
			get_parent().add_child(child)
			child.global_position = global_position + Vector2(randf_range(-s, s), randf_range(-s, s))

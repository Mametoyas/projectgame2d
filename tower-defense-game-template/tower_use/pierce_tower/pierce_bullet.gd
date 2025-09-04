# res://bullet/arrow_anim_bullet.gd
extends Area2D

@export var speed: float = 900.0
@export var life_time: float = 2.0
@export var damage: int = 1
@export var rotate_to_dir: bool = true
@export_node_path("AnimatedSprite2D") var anim_path: NodePath = "AnimatedSprite2D"

var dir: Vector2 = Vector2.RIGHT
var destroyed := false

@onready var anim: AnimatedSprite2D = get_node_or_null(anim_path)

func _ready() -> void:
	z_index = 300
	z_as_relative = false

	# Bullet ตรวจจับเฉพาะศัตรู (ดิน=1, บิน=2)
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)

	if rotate_to_dir:
		rotation = dir.angle()
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("fly"):
		anim.play("fly")

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	# อายุสูงสุด กันค้าง
	var t = get_tree().create_timer(life_time)
	t.timeout.connect(_on_timeout)

func _on_timeout() -> void:
	if destroyed:
		return
	destroyed = true
	# ปิดชนก่อนคิวฟรี (ปลอดภัยสำหรับ Web)
	set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	call_deferred("queue_free")

func set_data(new_dir: Vector2, new_damage: int) -> void:
	dir = new_dir.normalized()
	damage = new_damage
	if rotate_to_dir:
		rotation = dir.angle()

func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta

func _on_area_entered(a: Area2D) -> void:
	if destroyed:
		return
	var p := a.get_parent()
	if p and p.is_in_group("enemies"):
		if p.has_method("apply_damage"):
			p.call("apply_damage", damage)
		destroyed = true
		# ปิดชนแบบ deferred แล้วค่อยลบ (กันยิงซ้ำหลายครั้งใน 1 เฟรม)
		set_deferred("monitoring", false)
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		call_deferred("queue_free")

# (ถ้าต้องใช้ร่วมกับระบบที่เรียก damage ผ่าน method)
func get_damage() -> int:
	return damage

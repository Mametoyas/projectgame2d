# res://bullet/arrow_anim_bullet.gd
extends Area2D

@export var speed: float = 600.0
@export var damage: int = 8
@export var lifetime: float = 2.0
@export var pierce: int = 1
@export var rotate_to_dir: bool = true

var dir: Vector2 = Vector2.RIGHT
var alive: bool = true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var death_timer: Timer = $DeathTimer

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 0
	set_collision_mask_value(1, true) # ศัตรูพื้น
	set_collision_mask_value(2, true) # ศัตรูบิน

	if death_timer and not death_timer.timeout.is_connected(_on_life_over):
		death_timer.wait_time = lifetime
		death_timer.one_shot = true
		death_timer.start()
		death_timer.timeout.connect(_on_life_over)

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("fly"):
		anim.play("fly")

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if rotate_to_dir:
		rotation = dir.angle()

func set_data(new_dir: Vector2, new_damage: int) -> void:
	dir = new_dir.normalized()
	damage = new_damage
	if rotate_to_dir:
		rotation = dir.angle()

func _physics_process(delta: float) -> void:
	if not alive:
		return
	global_position += dir * speed * delta

func _on_area_entered(a: Area2D) -> void:
	if not alive:
		return
	var p := a.get_parent()
	if p != null and p.is_in_group("enemies"):
		_explode()   # ระเบิดเฉพาะเมื่อชนศัตรู

func _on_body_entered(b: Node) -> void:
	if not alive:
		return
	if b != null and b.is_in_group("enemies"):
		_explode()   # ระเบิดเฉพาะเมื่อชนศัตรู


func _hit(_n: Node) -> void:
	if not alive:
		return
	_explode()

func _explode() -> void:
	alive = false

	# เก็บศัตรูทุกตัวที่ทับพื้นที่ของกระสุน
	var seen := {}
	for a in get_overlapping_areas():
		var p := a.get_parent()
		if p and p.is_in_group("enemies"):
			seen[p] = true
	for b in get_overlapping_bodies():
		if b and b.is_in_group("enemies"):
			seen[b] = true

	# ทำดาเมจทุกราย
	for e in seen.keys():
		if e.has_method("apply_damage"):
			e.call("apply_damage", damage)

	# ปิดการชนแบบ deferred เพื่อเลี่ยง error flushing queries
	if shape:
		shape.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# เล่นแอนิเมชันระเบิด ถ้ามี ไม่มีก็ลบเลย
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("hit"):
		anim.play("hit")
		anim.animation_finished.connect(_on_anim_finished, Object.CONNECT_ONE_SHOT)
	else:
		queue_free()

func _on_anim_finished() -> void:
	queue_free()

func _on_life_over() -> void:
	queue_free()

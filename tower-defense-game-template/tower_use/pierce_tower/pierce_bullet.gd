# res://bullet/arrow_anim_bullet.gd
extends Area2D

@export var speed: float = 900.0
@export var life_time: float = 2.0
@export var damage: int = 1
@export var rotate_to_dir: bool = true
@export_node_path("AnimatedSprite2D") var anim_path: NodePath = "AnimatedSprite2D"

var dir: Vector2 = Vector2.RIGHT

@onready var anim: AnimatedSprite2D = get_node_or_null(anim_path)

func _ready() -> void:
	# ให้อยู่เหนือฉาก
	z_index = 300
	z_as_relative = false

	# ชนเฉพาะศัตรู
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(1, true)   # ศัตรูภาคพื้น
	set_collision_mask_value(2, true)   # ศัตรูบิน (ถ้ามี)

	# หมุนตามทิศ
	if rotate_to_dir:
		rotation = dir.angle()
	if anim:
		# ให้พาเรนต์หมุนแทน ไม่ให้สปรाइटหมุนซ้ำ
		#anim.rotation = 0
		if anim.sprite_frames and anim.sprite_frames.has_animation("fly"):
			anim.play("fly")

	# ชนกับ Area2D ของศัตรู
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	# อายุสูงสุด
	get_tree().create_timer(life_time).timeout.connect(queue_free)

func set_data(new_dir: Vector2, new_damage: int) -> void:
	dir = new_dir.normalized()
	damage = new_damage
	if rotate_to_dir:
		rotation = dir.angle()

func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta

func _on_area_entered(a: Area2D) -> void:
	var p := a.get_parent()
	if p and p.is_in_group("enemies"):
		if p.has_method("apply_damage"):
			p.call("apply_damage", damage)
		call_deferred("queue_free")

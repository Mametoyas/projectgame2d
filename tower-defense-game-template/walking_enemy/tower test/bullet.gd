extends Area2D

@export var speed: float = 900.0
@export var life_time: float = 2.0
@export var damage: int = 1

var dir: Vector2 = Vector2.RIGHT

@onready var sprite: Node2D = $ArrowTest   # ถ้า node ชื่ออื่น เปลี่ยนชื่อนี้ให้ตรง

func _ready() -> void:
	# ให้กระสุนอยู่เหนือฉาก
	z_index = 300
	z_as_relative = false

	# เปิดระบบชน และตั้งให้ชนกับศัตรูทุกประเภท
	monitoring = true
	monitorable = true
	collision_layer = 0                 # กระสุนไม่ต้องชนอะไรเป็นตัวถูกตรวจ
	collision_mask = 0
	set_collision_mask_value(1, true)   # ศัตรูภาคพื้น (Hitbox layer 1)
	set_collision_mask_value(2, true)   # ศัตรูบิน (Hitbox layer 2)

	# หมุนตัวกระสุนให้ตรงทิศ
	rotation = dir.angle()
	if sprite:
		sprite.rotation = 0              # ให้พาเรนต์หมุนแทน

	# รับสัญญาณชนกับ Area2D ของศัตรู
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	# อายุสูงสุด
	get_tree().create_timer(life_time).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta

func _on_area_entered(a: Area2D) -> void:
	var p := a.get_parent()
	if p and p.is_in_group("enemies"):
		# ศัตรูมีฟังก์ชัน apply_damage อยู่แล้ว
		p.apply_damage(damage)
		queue_free()

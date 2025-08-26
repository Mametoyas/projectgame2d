extends Area2D

@export var speed: float = 400.0
var damage: int = 5
var dir: Vector2 = Vector2.RIGHT

func _ready():
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(2.0).timeout
	queue_free()  # ลบกระสุนถ้าผ่านไป 2 วินาที

func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta

func _on_area_entered(area: Area2D):
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies"):
		parent.apply_damage(damage)
		queue_free()

extends Area2D   # หรือ Node2D แล้วแต่ root ของ buff_damage.tscn

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# เล่นอนิเมชันชื่อ "default"
	anim.play("default")
	# รอจนอนิเมชันจบแล้วลบ node ทิ้ง
	anim.animation_finished.connect(_on_anim_finished)

func _on_anim_finished() -> void:
	queue_free()

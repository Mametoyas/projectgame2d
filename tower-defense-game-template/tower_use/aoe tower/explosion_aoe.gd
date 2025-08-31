extends Area2D

@export var damage: int = 20
@export var lifetime: float = 0.12
@export var debug_print: bool = false

@onready var col: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	monitoring = true
	monitorable = true
	call_deferred("_blast")

func _blast() -> void:
	for a in get_overlapping_areas():
		_hit(a)
	for b in get_overlapping_bodies():
		_hit(b)

	if col:
		col.disabled = true
	monitoring = false
	monitorable = false

	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _hit(n: Node) -> void:
	if n == null:
		return
	var p: Node = n
	if n is Area2D and n.get_parent() != null:
		p = n.get_parent()
	if p.is_in_group("enemies") and p.has_method("apply_damage"):
		p.call("apply_damage", damage)
		if debug_print:
			print("[AOE] hit ", p.name, " dmg=", damage)

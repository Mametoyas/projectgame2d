extends Area2D

@export var speed: float = 520.0
@export var explosion_scene: PackedScene
@export var max_lifetime: float = 3.0

var dir: Vector2 = Vector2.RIGHT
var damage: int = 10

@onready var col: CollisionShape2D = $CollisionShape2D
var exploded: bool = false

func _ready() -> void:
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_auto_die()

func _physics_process(delta: float) -> void:
	position += dir * speed * delta

func _on_area_entered(_a: Area2D) -> void:
	if exploded:
		return
	call_deferred("_explode")

func _on_body_entered(_b: Node) -> void:
	if exploded:
		return
	call_deferred("_explode")

func _explode() -> void:
	if exploded:
		return
	exploded = true

	if col:
		col.disabled = true
	monitoring = false
	monitorable = false

	if explosion_scene:
		var e: Node2D = explosion_scene.instantiate() as Node2D
		var parent: Node = get_tree().current_scene
		if parent == null:
			parent = get_tree().root
		parent.add_child(e)
		e.global_position = global_position
		e.set("damage", damage)

	queue_free()

func _auto_die() -> void:
	await get_tree().create_timer(max_lifetime).timeout
	if not exploded:
		queue_free()

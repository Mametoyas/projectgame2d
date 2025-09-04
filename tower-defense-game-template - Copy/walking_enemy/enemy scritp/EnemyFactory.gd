extends Node
class_name EnemyFactory

@export var enemy_scene: PackedScene = preload("res://walking_enemy/enemy scritp/enemy.tscn")
static var DB: Dictionary = preload("res://walking_enemy/enemy scritp/EnemyDB.gd").ENEMY_DB

func _ready() -> void:
	add_to_group("enemy_factory")

func spawn(type_id: String, follower: PathFollow2D) -> Enemy:
	var cfg: Dictionary = DB.get(type_id, {})
	if cfg.is_empty():
		push_warning("Unknown enemy type: %s" % type_id)
		return null
	var e: Enemy = enemy_scene.instantiate() as Enemy
	e.setup(cfg.merged({"type_id": type_id}))
	e.follower = follower
	return e

static func spawn_configured(type_id: String, follower: PathFollow2D) -> Enemy:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var n := tree.get_first_node_in_group("enemy_factory")
	if n == null:
		return null
	# ป้องกัน invalid cast
	if n is EnemyFactory:
		return (n as EnemyFactory).spawn(type_id, follower)
	return null

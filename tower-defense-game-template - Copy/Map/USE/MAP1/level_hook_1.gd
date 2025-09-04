extends Node

@export var base_path: NodePath           # ชี้ไปที่ Node Base ของด่าน
@export_file("*.tscn") var lose_ui_path: String = "res://menu/lose_screen.tscn"

@onready var base_node: Node = get_node_or_null(base_path)

func _ready() -> void:
	# ต่อสัญญาณฐานแตก -> เปิดหน้าจอแพ้
	if base_node and base_node.has_signal("base_destroyed"):
		if not base_node.base_destroyed.is_connected(_on_base_destroyed):
			base_node.base_destroyed.connect(_on_base_destroyed)

func _on_base_destroyed() -> void:
	var ui_scene: PackedScene = preload("res://menu/lose_screen.tscn")
	if lose_ui_path != "":
		ui_scene = load(lose_ui_path) as PackedScene

	if ui_scene:
		var ui := ui_scene.instantiate() as Control
		var root := get_tree().current_scene
		if root:
			root.add_child(ui)
			ui.z_index = 9999
			get_tree().paused = true

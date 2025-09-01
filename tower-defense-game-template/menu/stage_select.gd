# res://ui/StageSelect.gd
extends Control

# ใส่พาธด่านใน Inspector ให้ครบ 5 ด่าน (หรือแก้ในโค้ดนี้ก็ได้)
@export_file("*.tscn") var stage1_path: String = "res://Map/USE/MAP1/Forest1.tscn"
@export_file("*.tscn") var stage2_path: String = "res://Map/USE/MAP2/Forest2.tscn"
@export_file("*.tscn") var stage3_path: String = "res://Map/USE/MAP3/Forest3.tscn"
@export_file("*.tscn") var stage4_path: String = "res://Map/USE/MAP4/Forest4.tscn"
@export_file("*.tscn") var stage5_path: String = "res://Map/USE/MAP5/Forest5.tscn"

@export_file("*.tscn") var main_menu_path: String = "res://menu/main_menu.tscn"

# อ้างปุ่มตามโครง Scene ที่ส่งมา (StageSelect/CenterContainer/Menu/…)
@onready var b1: Button = $CenterContainer/Menu/Stage1Btn
@onready var b2: Button = $CenterContainer/Menu/Stage2Btn
@onready var b3: Button = $CenterContainer/Menu/Stage3Btn
@onready var b4: Button = $CenterContainer/Menu/Stage4Btn
@onready var b5: Button = $CenterContainer/Menu/Stage5Btn
@onready var bBack: Button = $CenterContainer/Menu/BackBtn

func _ready() -> void:
	_wire(b1, stage1_path)
	_wire(b2, stage2_path)
	_wire(b3, stage3_path)
	_wire(b4, stage4_path)
	_wire(b5, stage5_path)

	if bBack:
		bBack.pressed.connect(_go_main)

func _wire(btn: Button, scene_path: String) -> void:
	if btn == null:
		return
	if scene_path == "":
		btn.disabled = true
		return
	# ใช้ Callable.bind เพื่อส่งพาธตอนกด
	btn.pressed.connect(Callable(self, "_go_scene").bind(scene_path))

func _go_scene(p: String) -> void:
	if p == "":
		return
	get_tree().change_scene_to_file(p)

func _go_main() -> void:
	_go_scene(main_menu_path)

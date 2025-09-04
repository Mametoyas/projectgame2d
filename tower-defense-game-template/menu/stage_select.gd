# res://ui/StageSelect.gd
extends Control
const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")

@export_file("*.tscn") var stage1_path: String = "res://Map/USE/MAP1/Forest1.tscn"
@export_file("*.tscn") var stage2_path: String = "res://Map/USE/MAP2/Forest2.tscn"
@export_file("*.tscn") var stage3_path: String = "res://Map/USE/MAP3/Forest3.tscn"
@export_file("*.tscn") var stage4_path: String = "res://Map/USE/MAP4/Forest4.tscn"
@export_file("*.tscn") var stage5_path: String = "res://Map/USE/MAP5/Forest5.tscn"
@export_file("*.tscn") var prize_path: String = "res://menu/prize.tscn"
@export_file("*.tscn") var main_menu_path: String = "res://menu/main_menu.tscn"

@onready var b1: Button = $CenterContainer/Menu/Stage1Btn
@onready var b2: Button = $CenterContainer/Menu/Stage2Btn
@onready var b3: Button = $CenterContainer/Menu/Stage3Btn
@onready var b4: Button = $CenterContainer/Menu/Stage4Btn
@onready var b5: Button = $CenterContainer/Menu/Stage5Btn
@onready var prize: Button = $Panel/prizeBtn
@onready var bBack: Button = $CenterContainer/Menu/BackBtn

func _ready() -> void:
	_connect_stage_button(b1, stage1_path)
	_connect_stage_button(b2, stage2_path)
	_connect_stage_button(b3, stage3_path)
	_connect_stage_button(b4, stage4_path)
	_connect_stage_button(b5, stage5_path)
	_connect_stage_button(prize, prize_path)

	if bBack:
		bBack.pressed.connect(_go_main)

	_refresh_lock_state()

func _connect_stage_button(btn: Button, path: String) -> void:
	if btn == null:
		return
	btn.pressed.connect(func():
		SFX.play_ui(SND_CLICK)
		if path != "":
			get_tree().change_scene_to_file(path))

func _refresh_lock_state() -> void:
	var unlocked: int = StageProgress.load_unlocked()  # ← ไม่มีอาร์กิวเมนต์

	# stage 1
	_set_btn_state(b1, unlocked >= 1, " ")

	# stage 2
	var label2: String = " "
	if unlocked < 2: label2 = "XXXX"
	_set_btn_state(b2, unlocked >= 2, label2)

	# stage 3
	var label3: String = " "
	if unlocked < 3: label3 = "XXXX"
	_set_btn_state(b3, unlocked >= 3, label3)

	# stage 4
	var label4: String = " "
	if unlocked < 4: label4 = "XXXX"
	_set_btn_state(b4, unlocked >= 4, label4)

	# stage 5
	var label5: String = " "
	if unlocked < 5: label5 = "XXXX"
	_set_btn_state(b5, unlocked >= 5, label5)
	
	var label6: String = "prize"
	if unlocked < 6: label6 = "XXXX"
	_set_btn_state(prize, unlocked >= 6, label6)

func _set_btn_state(btn: Button, enabled: bool, label: String) -> void:
	if btn == null:
		return
	btn.text = label
	btn.disabled = not enabled

func _go_main() -> void:
	SFX.play_ui(SND_CLICK)
	if main_menu_path != "":
		get_tree().change_scene_to_file(main_menu_path)

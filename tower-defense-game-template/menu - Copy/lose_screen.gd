extends Control

@export_file("*.tscn") var main_menu_path: String = "res://menu/main_menu.tscn"

@onready var retry_btn: Button = $Panel/RetryBtn
@onready var menu_btn:  Button = $Panel/MenuBtn

const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")

func _ready() -> void:
	# ให้ UI ตอบสนองแม้เกมถูก pause
	process_mode = Node.PROCESS_MODE_ALWAYS

	if retry_btn and not retry_btn.pressed.is_connected(_on_retry):
		retry_btn.pressed.connect(_on_retry)

	if menu_btn and not menu_btn.pressed.is_connected(_on_menu):
		menu_btn.pressed.connect(_on_menu)

func _on_retry() -> void:
	SFX.play_ui(SND_CLICK)
	var tree := get_tree()
	tree.paused = false

	var last_path: String = ""
	if tree.has_meta("last_level_path"):
		last_path = String(tree.get_meta("last_level_path"))

	if last_path != "" and ResourceLoader.exists(last_path):
		tree.change_scene_to_file(last_path)
	else:
		# เผื่อกรณีไม่ได้บันทึกไว้ ให้กลับเมนูหลักแทน
		if main_menu_path != "":
			tree.change_scene_to_file(main_menu_path)


func _on_menu() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().paused = false
	if main_menu_path != "":
		get_tree().change_scene_to_file(main_menu_path)

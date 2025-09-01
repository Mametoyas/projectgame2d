extends Panel

@export_file("*.tscn") var stage_select_path: String = "res://menu/stage_select.tscn"

@onready var return_btn: Button = $ReturnBtn  # หรือเปลี่ยนชื่อปุ่มเป็น ReturnBtn แล้วใช้ $ReturnBtn

func _ready() -> void:
	if return_btn and not return_btn.pressed.is_connected(_on_start):
		return_btn.pressed.connect(_on_start)

func _on_start() -> void:
	if stage_select_path != "":
		get_tree().change_scene_to_file(stage_select_path)

func _on_exit() -> void:
	get_tree().quit()

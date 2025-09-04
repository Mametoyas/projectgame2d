extends Panel
#
##@export_file("*.tscn") var PausePath: String = "res://menu/pause_menu.tscn"/
#
#@onready var return_btn: Button = $ReturnBtn  # หรือเปลี่ยนชื่อปุ่มเป็น ReturnBtn แล้วใช้ $ReturnBtn
#
#const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")
#
##func _ready() -> void:
	##if return_btn and not return_btn.pressed.is_connected(_on_start):
		##return_btn.pressed.connect(_on_start)
#
##func _on_start() -> void:
	##SFX.play_ui(SND_CLICK)
	##
	##if PausePath != "":
		##get_tree().change_scene_to_flie(PausePath)
#
#func _on_exit() -> void:
	#SFX.play_ui(SND_CLICK)
	#get_tree().quit()

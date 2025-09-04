extends Control


@export var main_menu: String = "res://menu/main_menu.tscn"

@onready var next_btn: Button = $next
@onready var back_btn: Button = $back
@onready var menu_btn: Button = $menu

const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")


func _ready() -> void:
	if not menu_btn.pressed.is_connected(_on_back):
		menu_btn.pressed.connect(_on_back)

func _on_back() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().change_scene_to_file(main_menu)

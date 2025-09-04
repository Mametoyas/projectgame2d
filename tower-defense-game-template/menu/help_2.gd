extends Control

@export var back_path: String = "res://menu/help3.tscn"
@export var main_menu: String = "res://menu/main_menu.tscn"
@export var next_path: String = "res://menu/help3.tscn"

@onready var next_btn: Button = $next
@onready var back_btn: Button = $back
@onready var menu_btn: Button = $menu

const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")


func _ready() -> void:
	if not next_btn.pressed.is_connected(_on_next):
		next_btn.pressed.connect(_on_next)
	if not back_btn.pressed.is_connected(_on_back):
		back_btn.pressed.connect(_on_back)
	if not menu_btn.pressed.is_connected(_on_back):
		menu_btn.pressed.connect(_on_back)

func _on_next() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().change_scene_to_file(next_path)

func _on_back() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().change_scene_to_file(back_path)
	
func _on_main() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().change_scene_to_file(main_menu)

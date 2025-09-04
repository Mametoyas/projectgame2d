# res://ui/main_menu.gd
extends Control

@export var stage_select_path: String = "res://menu/stage_select.tscn"
@export var select_help: String = "res://menu/help1.tscn"
@export var options_path: String = "res://menu/options_menu.tscn"


@onready var start_btn: Button = $Panel/StartButton
@onready var help_btn: Button = $Panel/HelpButton
@onready var exit_btn:  Button = $Panel/ExitButton

const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")


func _ready() -> void:
	if not start_btn.pressed.is_connected(_on_start):
		start_btn.pressed.connect(_on_start)
	if not exit_btn.pressed.is_connected(_on_exit):
		exit_btn.pressed.connect(_on_exit)
	if not help_btn.pressed.is_connected(_on_menu):
		help_btn.pressed.connect(_on_menu)

func _on_start() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().change_scene_to_flie(stage_select_path)

func _on_menu() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().change_scene_to_flie(select_help)

func _on_exit() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().quit()


func _on_button_2_pressed() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().change_scene_to_flie(options_path)
	

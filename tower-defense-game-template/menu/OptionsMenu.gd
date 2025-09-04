extends Control

@export var main_menu: String = "res://menu/main_menu.tscn"
const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#AudioServer.set_bus_volume_db(0, linear_to_db($AudioOptions/VBoxContainer/MasterSlider.value))
	#AudioServer.set_bus_volume_db(0, linear_to_db($AudioOptions/VBoxContainer/SFXSlider.value))
	#AudioServer.set_bus_volume_db(0, linear_to_db($AudioOptions/VBoxContainer/MusicSlider.value))



func _on_menu_pressed() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().change_scene_to_flie(main_menu)

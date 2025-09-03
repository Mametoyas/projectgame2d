extends Control

@export var main_menu: String = "res://menu/main_menu.tscn"
@onready var ResumBut: Button = $Resume
@onready var MainBut: Button = $MainMenu
@onready var QuitBut: Button = $QuitGame
#@onready var PauseSC: Scene = $QuitGame
const SND_CLICK := preload("res://audio/computer-mouse-click-02-383961.mp3")
# Called when the node enters the scene tree for the first time.
func _ready():
	self.visible= false
	if not ResumBut.pressed.is_connected(_on_next):
		ResumBut.pressed.connect(_on_next)
	if not MainBut.pressed.is_connected(_on_back):
		MainBut.pressed.connect(_on_back)
	if not QuitBut.pressed.is_connected(_on_quit):
		QuitBut.pressed.connect(_on_quit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	AudioServer.set_bus_volume_db(0, linear_to_db($AudioOptions/VBoxContainer/MasterSlider.value))


func _on_next() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().paused = false
	self.visible = false

func _on_quit() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().quit()

func _on_back() -> void:
	SFX.play_ui(SND_CLICK)
	get_tree().change_scene_to_file(main_menu)

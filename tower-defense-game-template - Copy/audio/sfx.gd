extends Node
@export var sfx_bus: String = "SFX"

func play_ui(stream: AudioStream) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = sfx_bus
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func play_2d(stream: AudioStream, pos: Vector2) -> void:
	var p := AudioStreamPlayer2D.new()
	p.stream = stream
	p.bus = sfx_bus
	p.position = pos
	p.max_polyphony = 16
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

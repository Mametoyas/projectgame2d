extends Node2D

@export var speed: float = 260.0
@export var run_anim_name: StringName = &"thief_run"
@export var rotate_with_path: bool = false

# ถ้า > 0 จะสเกลสปริตให้พอดีกับขนาดไทล์ โดย "ไม่ยืด" (รักษาอัตราส่วน)
@export var fit_to_tile: bool = false
@export var tile_size: int = 64

var pf: PathFollow2D
var anim: AnimatedSprite2D
var _last_pos: Vector2

func _ready() -> void:
	# กันสเกลเพี้ยนจากพาเรนต์ก่อน
	scale = Vector2.ONE

	# หา AnimatedSprite2D ตามชื่อที่เป็นไปได้
	anim = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim == null:
		anim = get_node_or_null("thief_walk") as AnimatedSprite2D

	pf = get_parent() as PathFollow2D

	if anim:
		# กันสเกลยืดเพี้ยน
		anim.scale = Vector2.ONE

		# เล่นแอนิเมชันแน่ ๆ
		if anim.sprite_frames and anim.sprite_frames.has_animation(run_anim_name):
			anim.play(run_anim_name)
		else:
			anim.play()

		# เร่ง/ผ่อนความเร็วอนิเมชันตาม speed (ปรับสูตรได้)
		anim.speed_scale = max(speed / 120.0, 0.1)

		# ปรับขนาดให้พอดีไทล์ โดยรักษาอัตราส่วน (ไม่ยืด)
		if fit_to_tile and anim.sprite_frames:
			var tex: Texture2D = anim.sprite_frames.get_frame_texture(run_anim_name, 0)
			if tex:
				var longer := float(max(tex.get_width(), tex.get_height()))
				if longer > 0.0:
					var s := float(tile_size) / longer
					anim.scale = Vector2(s, s)

	_last_pos = global_position

func _process(delta: float) -> void:
	if pf == null:
		return

	pf.progress += speed * delta
	global_position = pf.global_position

	if rotate_with_path:
		rotation = pf.rotation
	else:
		# ไม่หมุนทั้งตัวก็หันซ้าย/ขวาตามทิศทางได้
		var dx := global_position.x - _last_pos.x
		if anim and absf(dx) > 0.05:
			anim.flip_h = dx < 0.0

	_last_pos = global_position

	if pf.progress_ratio >= 1.0:
		queue_free()

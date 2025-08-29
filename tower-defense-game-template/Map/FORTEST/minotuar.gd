# sheep_anim.gd
extends AnimatedSprite2D

@export var anim_name: StringName = &"mino_run"        # ใส่ชื่อแอนิเมชันที่มีใน SpriteFrames
@export var random_start := true                   # เริ่มคนละเฟรม ไม่ซิงค์กัน
@export var random_speed_range := Vector2(0.9,1.2) # เร็วช้าต่างกันนิด ๆ
@export var random_flip := true                    # สลับหันซ้าย/ขวาบางตัว
@export var bobbing := true                        # เด้งเบา ๆ ให้น่ารัก
@export var bob_pixels := 2.0
@export var bob_time := 0.6

func _ready():
	# เลือกแอนิเมชันให้ถูกต้อง
	if sprite_frames:
		if not sprite_frames.has_animation(anim_name):
			var names := sprite_frames.get_animation_names()
			if names.size() > 0:
				anim_name = names[0]
		animation = anim_name

	# สุ่มจุดเริ่ม / ความเร็ว / การหัน
	if random_start and sprite_frames:
		frame = randi() % sprite_frames.get_frame_count(animation)
		frame_progress = randf()
	if random_speed_range.x > 0.0:
		speed_scale = randf_range(random_speed_range.x, random_speed_range.y)
	if random_flip:
		flip_h = randf() < 0.5

	play()

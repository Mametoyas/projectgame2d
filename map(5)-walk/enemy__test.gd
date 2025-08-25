extends Node2D

@export var speed: float = 260.0
@export var run_anim_name: StringName = &"thief_run"

var pf: PathFollow2D
@onready var anim: AnimatedSprite2D = (
	has_node("AnimatedSprite2D") ? $AnimatedSprite2D :
	has_node("thief_walk") ? $thief_walk : null
)

func _ready():
	pf = get_parent() as PathFollow2D
	if pf == null:
		push_error("Enemy.gd: pf == null (ศัตรูไม่ได้อยู่ใต้ PathFollow2D)")
	else:
		var path := pf.get_parent() as Path2D
		if path and path.curve:
			var L := path.curve.get_baked_length()
			if L <= 0.0:
				push_error("Enemy.gd: Path length = 0 (Path2D ต้องมี >= 2 จุด)")
		else:
			push_error("Enemy.gd: ไม่มี Path2D/curve")

	if anim:
		if anim.sprite_frames and anim.sprite_frames.has_animation(run_anim_name):
			anim.play(run_anim_name)
		else:
			anim.play()

func _process(delta):
	if pf == null:
		return
	if speed <= 0.0:
		push_warning("Enemy.gd: speed <= 0, ปรับให้มากกว่า 0"); return

	pf.progress += speed * delta
	global_position = pf.global_position
	# rotation = pf.rotation    # เปิดถ้าอยากหมุนตามเส้น

	if pf.progress_ratio >= 1.0:
		queue_free()

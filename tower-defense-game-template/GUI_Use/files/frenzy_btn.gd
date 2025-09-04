# res://ui/skill_frenzy_button.gd
extends Button

@export var frenzy_time: float = 8.0
@export var dmg_mult: float = 1.5
@export var rof_mult: float = 0.65      # ยิงไวขึ้น (ลดช่วงหน่วง)
@export var cd_frenzy: float = 18.0      # คูลดาวน์ปุ่ม

var ready_frenzy := true
var _cd_left := 0.0
var _orig_text: String = ""

func _ready() -> void:
	_orig_text = text if text != "" else "Frenzy"
	pressed.connect(_cast_frenzy)
	set_process(true)
	_update_visual()

func _process(delta: float) -> void:
	if not ready_frenzy:
		_cd_left = max(0.0, _cd_left - delta)
		text = "%s (%.0f)" % [_orig_text, ceil(_cd_left)]
		if _cd_left <= 0.0:
			ready_frenzy = true
			text = _orig_text
			_update_visual()

func _update_visual() -> void:
	disabled = not ready_frenzy

func _start_cd(sec: float) -> void:
	ready_frenzy = false
	_cd_left = sec
	_update_visual()

func _cast_frenzy() -> void:
	if not ready_frenzy:
		return
	_start_cd(cd_frenzy)
	for t in get_tree().get_nodes_in_group("towers"):
		_buff_tower(t)

func _buff_tower(t: Node) -> void:
	# สำรองค่าสถานะเดิม
	if not t.has_meta("orig_damage"):
		var d = null
		d = t.get("damage")    # ถ้าไม่มีพร็อพฯ นี้ d จะเป็น null
		if d != null:
			t.set_meta("orig_damage", d)
	if not t.has_meta("orig_interval") and t.has_node("ShootTimer"):
		var st := t.get_node("ShootTimer") as Timer
		t.set_meta("orig_interval", st.wait_time)

	# ใส่บัฟ
	var cur_dmg = t.get("damage")
	if cur_dmg != null:
		t.set("damage", int(round(float(cur_dmg) * dmg_mult)))
	if t.has_node("ShootTimer"):
		var st2 := t.get_node("ShootTimer") as Timer
		st2.wait_time = st2.wait_time * rof_mult

	# ตั้งเวลาให้คืนค่า
	var tm := Timer.new()
	tm.one_shot = true
	tm.wait_time = frenzy_time
	t.add_child(tm)
	tm.timeout.connect(func():
		if t and is_instance_valid(t):
			if t.has_meta("orig_damage"):
				t.set("damage", t.get_meta("orig_damage"))
				t.remove_meta("orig_damage")
			if t.has_node("ShootTimer") and t.has_meta("orig_interval"):
				var st3 := t.get_node("ShootTimer") as Timer
				st3.wait_time = float(t.get_meta("orig_interval"))
				t.remove_meta("orig_interval")
		tm.call_deferred("queue_free"))
	tm.start()

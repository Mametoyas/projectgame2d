extends Node

var frenzy_time := 8.0
var dmg_mult    := 1.5
var rof_mult    := 0.65   # ลดคูลดาวน์ยิงลง (เร็วขึ้น)

@export var button_path: NodePath = ^"../ClickSkillBtn"

func _cast_frenzy() -> void:
	if not ready_frenzy: return
	ready_frenzy = false
	_update_buttons()
	_start_cd(cd_frenzy, func(v): ready_frenzy = v)

	for t in get_tree().get_nodes_in_group("towers"):
		_buff_tower(t)

func _buff_tower(t: Node) -> void:
	# เก็บเดิม
	if not t.has_meta("orig_damage") and t.has_variable("damage"):
		t.set_meta("orig_damage", t.get("damage"))
	if not t.has_meta("orig_interval") and t.has_node("ShootTimer"):
		var st := t.get_node("ShootTimer") as Timer
		t.set_meta("orig_interval", st.wait_time)

	# ใส่บัฟ
	if t.has_variable("damage"):
		t.set("damage", int(round(float(t.get("damage")) * dmg_mult)))
	if t.has_node("ShootTimer"):
		var st := t.get_node("ShootTimer") as Timer
		st.wait_time = st.wait_time * rof_mult

	# ตั้งคืนค่าหลังหมดเวลา
	var tm := Timer.new()
	tm.one_shot = true
	tm.wait_time = frenzy_time
	t.add_child(tm)
	tm.timeout.connect(func():
		if t and is_instance_valid(t):
			if t.has_variable("damage") and t.has_meta("orig_damage"):
				t.set("damage", t.get_meta("orig_damage"))
				t.remove_meta("orig_damage")
			if t.has_node("ShootTimer") and t.has_meta("orig_interval"):
				var st := t.get_node("ShootTimer") as Timer
				st.wait_time = float(t.get_meta("orig_interval"))
				t.remove_meta("orig_interval")
		tm.queue_free())
	tm.start()

extends Node

const SAVE_PATH := "user://progress.save"

static func load_unlocked() -> int:
	var n: int = 1
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		n = int(f.get_as_text())
		f.close()
	return max(n, 1)

static func save_unlocked(n: int) -> void:
	var m: int = max(n, 1)  # << ใส่ชนิดให้ชัด
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(str(m))
		f.close()

static func unlock_if_higher(level: int) -> void:
	var cur: int = load_unlocked()  # << ใส่ชนิดให้ชัด
	if level > cur:
		save_unlocked(level)

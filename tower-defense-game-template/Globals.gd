extends Node

func is_web() -> bool:
	return OS.has_feature("web") or Engine.has_singleton("JavaScript")

func safe_pid() -> int:
	if is_web():
		return 0
	return OS.get_process_id()

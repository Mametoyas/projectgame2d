# res://ui/click_damage_skill.gd
extends Node
#
## ปรับค่าได้ตามต้องการ
#@export var duration: float = 5.0      # ระยะเวลาใช้งานสกิล (วินาที)
#@export var cooldown: float = 12.0     # คูลดาวน์หลังหมดเวลา (วินาที)
#@export var damage: int = 25           # ดาเมจต่อ 1 คลิก
#
## ชี้ไปยังปุ่มใน HUD
#@export var button_path: NodePath = ^"../ClickSkillBtn"
#
#@onready var btn: Button = get_node(button_path) as Button
#
#var _active_until: float = 0.0
#var _cooldown_until: float = 0.0
#
#func _ready() -> void:
#
	#if btn and not btn.pressed.is_connected(_on_press):
		#btn.pressed.connect(_on_press)
	#_update_button()
#
#func _process(_dt: float) -> void:
	#_update_button()
#
#func _unhandled_input(event: InputEvent) -> void:
	## ใช้ได้เฉพาะช่วงสกิลทำงาน และคลิกซ้าย
	#if _is_active() and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#_click_damage()
#
#func _on_press() -> void:
	#var now := Time.get_ticks_msec() / 1000.0
	#if now < _cooldown_until:
		#return
	#_active_until   = now + duration
	#_cooldown_until = _active_until + cooldown
	#_update_button()
#
#func _is_active() -> bool:
	#return Time.get_ticks_msec() / 1000.0 < _active_until
#
#func _update_button() -> void:
	#if btn == null: return
	#var now := Time.get_ticks_msec() / 1000.0
	#if _is_active():
		#btn.disabled = false
		#btn.text = "Click DMG (%.1fs)" % [max(0.0, _active_until - now)]
	#elif now < _cooldown_until:
		#btn.disabled = true
		#btn.text = "Cooldown (%.1fs)" % [max(0.0, _cooldown_until - now)]
	#else:
		#btn.disabled = false
		#btn.text = "Click DMG"
#
#func _click_damage() -> void:
	## หาตำแหน่งเมาส์ในพิกัดโลก แบบไม่ต้องพึ่ง screen_to_world()
	#var world_pos: Vector2
	#var world_root := get_tree().current_scene as Node2D
	#if world_root:
		## วิธีที่เสถียรที่สุดสำหรับ 2D — อิงกล้องปัจจุบันอัตโนมัติ
		#world_pos = world_root.get_global_mouse_position()
	#else:
		## เผื่อฉากไม่ใช่ Node2D (ไม่ค่อยเกิด) ก็พยายามใช้กล้อง ถ้ามี
		#var cam := get_viewport().get_camera_2d()
		#if cam and cam.has_method("screen_to_world"):
			#world_pos = cam.call("screen_to_world", get_viewport().get_mouse_position())
		#else:
			## fallback สุดท้าย: ใช้พิกัดจอ (อาจคลาดถ้ามีกล้องซูม/เลื่อน)
			#world_pos = get_viewport().get_mouse_position()
#
	#var p := PhysicsPointQueryParameters2D.new()
	#p.position = world_pos
	#p.collide_with_areas = true
	#p.collide_with_bodies = false
	#p.collision_mask = 0xFFFFFFFF
#
	#var space := get_viewport().get_world_2d().direct_space_state
	#var hits := space.intersect_point(p, 16)
#
	#for h in hits:
		#var a := h["collider"] as Area2D
		#if a:
			#var owner := a.get_parent()
			#if owner and owner.is_in_group("enemies"):
				#if owner.has_method("apply_damage"):
					#owner.call("apply_damage", damage)
				#elif owner.has_method("die"):
					#owner.call("die")
				#break

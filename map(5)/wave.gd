# SpawnWave.gd
extends Resource
class_name SpawnWave

@export var delay_before: float = 1.5   # หน่วงก่อนเริ่มเวฟนี้ (วินาที)
@export var count: int = 10             # จำนวนศัตรูในเวฟนี้
@export var interval: float = 0.8       # เวลาห่างระหว่างตัว (วินาที)

# วิธีเลือกเส้นของเวฟนี้ (ใช้กับสปอว์นเนอร์)
enum PathSelectMode { PER_ENEMY_RANDOM, ROUND_ROBIN, SINGLE_ACTIVE, WEIGHTED_RANDOM }
@export var select_mode: PathSelectMode = PathSelectMode.PER_ENEMY_RANDOM
@export var active_path_index: int = 0               # ใช้เมื่อ SINGLE_ACTIVE
@export var path_weights: PackedFloat32Array = []    # ใช้เมื่อ WEIGHTED_RANDOM เช่น [1,2,1]

# (ออปชัน) กระจายสุ่มเพิ่ม/ลดจำนวนเล็กน้อย
@export var count_variation: int = 0  # เช่น 2 -> จะสุ่มเป็น count±2

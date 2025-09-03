# scripts/EnemyDB.gd
const ENEMY_DB := {
	"crawler": {   # 1) มาตรฐาน
		"hp": 25, "speed": 120, "reward": 4,
		"armor": 0, "regen": 0, "flying": false, "shield_hp": 0,
		"on_death_spawn": null, "size": 1.0,
		"anim": "crawler_walk"
	},
	"runner": {    # 2) ไว บาง
		"hp": 16, "speed": 180, "reward": 5,
		"armor": 0, "regen": 0, "flying": false, "shield_hp": 0,
		"on_death_spawn": null, "size": 0.9,
		"anim": "runner_run"
	},
	"tank": {      # 3) อึด ช้า เกราะ
		"hp": 90, "speed": 90, "reward": 8,
		"armor": 6, "regen": 0, "flying": false, "shield_hp": 0,
		"on_death_spawn": null, "size": 1.2,
		"anim": "tank_walk"
	},
	"regenerator": {  # 4) ฟื้นเลือด
		"hp": 40, "speed": 120, "reward": 7,
		"armor": 1, "regen": 3, "flying": false, "shield_hp": 0,
		"on_death_spawn": null, "size": 1.0,
		"anim": "regen_walk"
	},
	"splitter": {  # 5) ตายแตกเป็นลูก
		"hp": 50, "speed": 110, "reward": 10,
		"armor": 2, "regen": 0, "flying": false, "shield_hp": 0,
		"on_death_spawn": {"type_id": "crawler", "count": 5, "spread": 40}, "size": 1.5,
		"anim": "split_walk"
	},
	"shielded": {  # 6) มีโล่ก่อนเลือดจริง
		"hp": 35, "speed": 115, "reward": 9,
		"armor": 0, "regen": 0, "flying": false, "shield_hp": 30,
		"on_death_spawn": null, "size": 1.0,
		"anim": "shield_walk"
	},
	"flyer": {     # 7) บิน
		"hp": 28, "speed": 160, "reward": 9,
		"armor": 0, "regen": 0, "flying": true, "shield_hp": 0,
		"on_death_spawn": null, "size": 0.95,
		"anim": "flyer_fly"
	},
	"money": {     # 8) money
		"hp": 6, "speed": 180, "reward": 500,
		"armor": 0, "regen": 0, "flying": false, "shield_hp": 0,
		"on_death_spawn": null, "size": 1.0,
		"anim": "money_run"
	},
	"snake": {   #) 
		"hp": 10, "speed": 120, "reward": 3,
		"armor": 0, "regen": 0, "flying": false, "shield_hp": 0,
		"on_death_spawn": null, "size": 0.6,
		"anim": "snake_run"
	},
	"fish1": {   #) 
		"hp": 34, "speed": 100, "reward": 6,
		"armor": 0, "regen": 0, "flying": false, "shield_hp": 0,
		"on_death_spawn": null, "size": 1.0,
		"anim": "fish1_run"
	},
	"Minotaur": {   #) 
		"hp": 100, "speed": 100, "reward": 200,
		"armor": 10, "regen": 10, "flying": false, "shield_hp": 0,
		"on_death_spawn": null, "size": 1.3,
		"anim": "Minotaur_Walk"
	},
	"HarpoonFish": {   #) 
		"hp": 90, "speed": 120, "reward": 6,
		"armor": 0, "regen": 0, "flying": false, "shield_hp": 10,
		"on_death_spawn": null, "size": 1.0,
		"anim": "HarpoonFish_Run"
	},
	"Gnome": {   #) 
		"hp": 20, "speed": 120, "reward": 6,
		"armor": 0, "regen": 0, "flying": false, "shield_hp": 0,
		"on_death_spawn": null, "size": 0.7,
		"anim": "Gnome_Run"
	},
	"Gnoll": {   #) 
		"hp": 20, "speed": 120, "reward": 6,
		"armor": 0, "regen": 0, "flying": false, "shield_hp": 0,
		"on_death_spawn": null, "size": 1.0,
		"anim": "Gnoll_Walk"
	},
}

class_name EnemyClockwork extends BaseEnemyManager



const HIT_BOX = preload("res://scenes/enemy/base/hit_box.tscn")

@export var max_distance   : float = 800.0
@export var flash_time     : float = 0.05
@export var cooldown_time  : float = 0.5
@export var damage         : int   = 10

var hit_box:HitBox

var _ready_to_fire: bool = true
var _has_attacked: bool = false

func _ready() -> void:
	super._ready()   
	hit_box = HIT_BOX.instantiate()
	base_enemy_body.add_child(hit_box)
	
	if base_enemy_body:
		base_enemy_body.state_changed.connect(_on_state_changed)

func _on_state_changed(state):
	if state == base_enemy_body.State.ATTACK and not _has_attacked:
		_has_attacked = true
		await attack()
	elif state != base_enemy_body.State.ATTACK:
		_has_attacked = false  


func attack():
	for body in hit_box.get_overlapping_bodies():
		if body.is_in_group("Player"):
			# ---‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑
			# Put whatever should happen when the player is in the hit box here
			# e.g. call death signal 
			# ---‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑‑
			print("Player detected in hit box!")
			base_enemy_body.enter_state(base_enemy_body.State.IDLE)
		print(body)

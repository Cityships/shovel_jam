class_name EnemyClockwork extends BaseEnemyManager


@export var max_distance   : float = 800.0
@export var flash_time     : float = 0.05
@export var cooldown_time  : float = 0.5
@export var damage         : int   = 10

var _ready_to_fire: bool = true
var _has_attacked: bool = false

func _ready() -> void:
	super._ready()   
	
	if base_enemy_body:
		base_enemy_body.state_changed.connect(_on_state_changed)

func _on_state_changed(state):
	if state == base_enemy_body.State.ATTACK and not _has_attacked:
		_has_attacked = true
		await attack()
	elif state != base_enemy_body.State.ATTACK:
		_has_attacked = false  


func attack():
	pass

class_name EnemyClockwork extends BaseEnemyManager



const HIT_BOX = preload("res://scenes/enemy/base/hit_box.tscn")

@export var leap_force     : float = 220.0 
@export var jump_velocity  : float = -300.0  
@export var max_distance   : float = 800.0
@export var flash_time     : float = 0.05
@export var cooldown_time  : float = 0.5
@export var damage         : int   = 10
@export var animated_sprite: SpriteFrames

var hit_box:HitBox

var _ready_to_fire: bool = true
var _has_attacked: bool = false

func _ready() -> void:
	super._ready()

	if base_enemy_body:
		hit_box = HIT_BOX.instantiate()
		base_enemy_body.add_child(hit_box)
		base_enemy_body.state_changed.connect(_on_state_changed)

		base_enemy_body.set_resources(animated_sprite)  # ← fixed var name
		base_enemy_body.enter_state(base_enemy_body.State.MOVE)

func _on_state_changed(state):
	if state == base_enemy_body.State.ATTACK and not _has_attacked:
		_has_attacked = true
		attack()
	elif state != base_enemy_body.State.ATTACK:
		_has_attacked = false

func attack() -> void:
	print("Attack")

	for body in hit_box.get_overlapping_bodies():
		if not body.is_in_group("Player"):
			continue

		print("Player detected in hit box!")

		# ── Leap toward the player ────────────────────────────────
		var dir = (body.global_position - base_enemy_body.global_position).normalized()
		base_enemy_body.velocity.x = dir.x * leap_force  
		base_enemy_body.velocity.y = jump_velocity     
		GlobalEvents.player_death.emit()
		await get_tree().create_timer(1.2).timeout   # > respawn tween length
		_has_attacked = false
		base_enemy_body.velocity = Vector2.ZERO
		base_enemy_body.enter_state(base_enemy_body.State.MOVE)
		

## MenInBlack.gd ─ Enemy laser attacker
## =============================================================
## Enemy manager for the “Men In Black” archetype.
##
## This enemy fires a single, hitscan‑style laser every time its
## underlying `BaseEnemyBody` enters the **ATTACK** state. The shot is:
##   • Visualised with a `Line2D` (`beam`).
##   • Evaluated for collision with a `RayCast2D` (`ray`).
##   • Limited to `max_distance` pixels and deals `damage` on hit.
##
## High‑level flow:
##   1. **ATTACK** → `shoot_laser()` (once).
##   2. Beam visible for `flash_time` seconds.
##   3. Cool‑down for the remaining `cooldown_time`.
##   4. Enemy enters **WIND_UP**, awaiting the next AI decision.
##
## The AI movement/path‑finding lives in `BaseEnemyManager`; this script
## only augments the attack behaviour.
class_name MenInBlack
extends BaseEnemyManager

# ------------------------------------------------------------------
# Node references
# ------------------------------------------------------------------


const SHOOT_ATTACK = preload("res://scenes/enemy/base/shoot_attack.tscn")

@onready var muzzle: Node2D = %Muzzle
@onready var laser_pivot: Node2D
@onready var ray: RayCast2D
@onready var beam: Line2D
# ------------------------------------------------------------------
# Tunable parameters (visible in the Inspector)
# ------------------------------------------------------------------

## Maximum distance (in pixels) the laser can travel.
@export var max_distance   : float = 800.0

## How long (in seconds) the beam stays visible after firing.
@export var flash_time     : float = 0.05

## Cool‑down (in seconds) between successive shots.
@export var cooldown_time  : float = 0.5

## Amount of damage inflicted on a hit target.
@export var damage         : int   = 10

@export var range:int = 150

@export var animxzated_sprite: SpriteFrames

# ------------------------------------------------------------------
# Internal state flags
# ------------------------------------------------------------------

## True if the laser is not on cool‑down.
var _ready_to_fire: bool = true

## Guard‑flag to ensure only one shot per ATTACK state.
var _has_fired_during_attack: bool = false


func _ready() -> void:
	super._ready()
	
	if base_enemy_body:
		laser_pivot = SHOOT_ATTACK.instantiate()
		base_enemy_body.add_child(laser_pivot) 
		laser_pivot.position = muzzle.position 
		base_enemy_body.collider.size = Vector2(17, 34) 
		ray  = laser_pivot.get_node("%Ray")
		beam = laser_pivot.get_node("%Beam")
		base_enemy_body.attack_range = 150
		base_enemy_body.state_changed.connect(_on_state_changed)
		base_enemy_body.set_resources(animxzated_sprite)
		base_enemy_body.enter_state(base_enemy_body.State.MOVE)




## Handles BaseEnemyBody state changes.
func _on_state_changed(state: BaseEnemyBody.State) -> void:
	if state == base_enemy_body.State.ATTACK and not _has_fired_during_attack:
		_has_fired_during_attack = true
		await shoot_laser()
		print("pew")  # Debug SFX placeholder
	elif state != base_enemy_body.State.ATTACK:
		_has_fired_during_attack = false
## Performs the laser attack.
##
## The method:
##   1. Enables the `RayCast2D` and aims it along the current move direction.
##   2. Checks for collision; if a body with `apply_damage(int)` is hit
##      that method is invoked.
##   3. Draws the `Line2D` beam for `flash_time` seconds.
##   4. Waits out the remaining `cooldown_time`, then resets state and
##      transitions the enemy into **WIND_UP**.




func shoot_laser() -> void:
	if not _ready_to_fire:
		return
	_ready_to_fire = false  # Lock until cooldown completes.
	if base_enemy_body._move_dir > 0:
		laser_pivot.position = Vector2(11, -13)
	if base_enemy_body._move_dir < 0:
		laser_pivot.position = Vector2(-11, -13)
	ray.enabled = true

	# Aim along the body’s facing direction (‑1 or +1 on the X axis).
	var aim_direction: Vector2 = Vector2(base_enemy_body._move_dir, 0).normalized()
	var aim_end      : Vector2 = global_position + aim_direction * max_distance
	ray.target_position = ray.to_local(aim_end)
	ray.force_raycast_update()
	var body = ray.get_collider()
	var hit_pos: Vector2
	if ray.is_colliding():
		hit_pos = ray.get_collision_point()
		
		
	else:
		hit_pos = aim_end
		print(hit_pos)

	# Draw the beam.
	beam.global_position = ray.global_position
	beam.points = [Vector2.ZERO, hit_pos - beam.global_position]
	## Delay for animation. 
	await get_tree().create_timer(0.3).timeout
	beam.visible = true

	## Flash beam visibility.
	await get_tree().create_timer(flash_time).timeout
	beam.visible = false
	ray.enabled = false
	if body.is_in_group("Player"):
		GlobalEvents.player_death.emit()

	## Finish cooldown period.
	await get_tree().create_timer(cooldown_time - flash_time).timeout
	_ready_to_fire = true

	## Return to WIND_UP so the FSM can transition again.
	base_enemy_body.enter_state(base_enemy_body.State.WIND_UP)

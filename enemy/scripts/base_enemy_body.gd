class_name BaseEnemyBody extends CharacterBody2D
## Thinking of using this to hold Movement Logic. 
## Concrete enemies (e.g. Patroller, Chaser) extend and implement _process_state().

## ───────── CONFIGURABLE STATS ─────────

# ───────── CONFIGURABLE STATS ─────────
@export var max_speed  : float = 60.0   # walk speed
@export var accel      : float = 500.0  # ground acceleration
@export var gravity    : float = 900.0  # downward force
@export var turn_delay : float = 0.12   # seconds to wait before flipping

# ───────── RUNTIME STATE ─────────
var _move_dir   : int   = -1     ## -1 = left, 1 = right
var _turn_timer : float = 0.0

enum { STATE_IDLE, STATE_MOVE, STATE_STUNNED }
var _state : int = STATE_IDLE

@onready var ray_front : RayCast2D = %RayFront     
@onready var ray_down  : RayCast2D = %RayDown      
@onready var sprite: Sprite2D = %Sprite


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_process_state(delta)
	move_and_slide()

## ───────── STATE MACHINE ─────────
func _process_state(delta: float) -> void:
	match _state:
		STATE_IDLE:
			velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)

		STATE_MOVE:
			_patrol_ground(delta)

		STATE_STUNNED:
			pass   ## TODO: knock-back, stun etc.

func enter_state(new_state: int) -> void:
	_state = new_state

# ───────── MOVEMENT HELPERS ─────────
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

func _patrol_ground(delta: float) -> void:
	if _should_turn():
		_turn_timer += delta
		if _turn_timer >= turn_delay:
			_move_dir *= -1
			_turn_timer = 0.0
			_flip_rays()
			print(">>> FLIPPED!  new dir:", _move_dir)
	else:
		_turn_timer = 0.0

	velocity.x = move_toward(
		velocity.x,
		_move_dir * max_speed,
		accel * delta
	)

func _flip_rays() -> void:
	ray_front.target_position.x =  abs(ray_front.target_position.x) * _move_dir
	ray_down.target_position.x  =  abs(ray_down.target_position.x)  * _move_dir
	ray_front.force_raycast_update() 
	ray_down.force_raycast_update() 
	sprite.flip_h = _move_dir < 0       


func _should_turn() -> bool:
	var should_turn := ray_front.is_colliding() or not ray_down.is_colliding()
	if should_turn:
		push_warning("Turn — front:", ray_front.is_colliding(),
		"  ground:", ray_down.is_colliding())
		return true
	else:
		return false

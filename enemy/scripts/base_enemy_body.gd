class_name BaseEnemyBody extends CharacterBody2D
## Thinking of using this to hold Movement Logic. 
## Concrete enemies (e.g. Patroller, Chaser) extend and implement _process_state().

#region Local signal bus
#This section is for signals that should be inherited
signal state_changed
signal emp_disabled
#endregion 

## ───────── CONFIGURABLE STATS ─────────
@export var max_speed  : float = 60.0   
@export var accel      : float = 500.0  
@export var gravity    : float = 900.0  
@export var turn_delay : float = 0.12 

## ───────── RUNTIME STATE ─────────
var _move_dir   : int   = -1     ## -1 = left, 1 = right
var _turn_timer : float = 0.0

enum { STATE_IDLE, STATE_MOVE, STATE_STUNNED }
var _state : int = STATE_IDLE

@onready var ray_player: RayCast2D = %RayPlayer
@onready var ray_front : RayCast2D = %RayFront     
@onready var ray_down  : RayCast2D = %RayDown      
@onready var debug: Label = %Debug
@onready var sprite: Sprite2D = %VisualTreeRoot


func _ready() -> void:
	emp_disabled.connect(try_emp_stun)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_process_state(delta)
	move_and_slide()
	_update_label()

## ───────── STATE MACHINE ─────────
func _process_state(delta: float) -> void:
	match _state:
		STATE_IDLE:
			velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)

		STATE_MOVE:
			_patrol_ground(delta)

		STATE_STUNNED:
			pass   ## TODO: knock-back, stun etc.

func try_emp_stun(duration):
	var tween = create_tween()
	tween.tween_callback(func():_state = STATE_IDLE)
	tween.chain().tween_interval(duration)
	tween.chain().tween_callback(func():_state = STATE_MOVE)

func enter_state(new_state: int) -> void:
	state_changed.emit(new_state) #example usage of local event bus
	_state = new_state

## ───────── MOVEMENT HELPERS ─────────
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
	ray_player.target_position.x  =  abs(ray_player.target_position.x)  * _move_dir
	ray_front.force_raycast_update() 
	ray_down.force_raycast_update() 
	ray_player.force_raycast_update()
	sprite.flip_h = _move_dir < 0       


func _should_turn() -> bool:
	var should_turn := ray_front.is_colliding() or not ray_down.is_colliding()
	if should_turn:
		push_warning("Turn — front:", ray_front.is_colliding(),
		"  ground:", ray_down.is_colliding())
		return true
	else:
		return false

func chase_bubble_start():
	chase_bubble.set_visible(true)
	
	
	pass

func _update_label():
	debug.text = ["Idle", "Move", "Stunned"][_state]

func _apply_stun():
	pass

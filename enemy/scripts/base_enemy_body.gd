class_name BaseEnemyBody extends CharacterBody2D
## Thinking of using this to hold Movement Logic. 
## Concrete enemies (e.g. Patroller, Chaser) extend and implement _process_state().

#region Local signal bus
#This section is for signals that should be inherited
signal state_changed
signal emp_disabled
#endregion 



## ───────── CONFIGURABLE STATS ─────────
@export var max_speed  : float = 60.0   ## walk speed
@export var accel      : float = 500.0  ## ground acceleration
@export var gravity    : float = 900.0  ## downward force
@export var turn_delay : float = 0.12   ## seconds to wait before flipping
@export var target_offset: Vector2 = Vector2(0.5, 0.0)
@export var attack_range: float = 64.0  # Start large
@export var wind_up_delay: float = 3.0
@onready var wind_up: Timer = %WindUP

var _move_dir   : int   = -1     ## -1 = left, 1 = right
var _turn_timer : float = 0.0
var _target_position : Vector2 = Vector2.ZERO  
var _windup_started: bool = false
## ───────── STATE ─────────
enum State { IDLE, MOVE, STUNNED , CHASE, ATTACK, WIND_UP }
@export var _state: State = State.IDLE


## ───────── On Ready ──────────────────────────|
@onready var vision_2: RayCast2D = %RayVision2  
@onready var vision: RayCast2D = $RayVision
@onready var ray_front : RayCast2D = %RayFront     
@onready var ray_down  : RayCast2D = %RayDown      
@onready var sprite: AnimatedSprite2D = %VisualTreeRoot
@onready var debug: Label = %Debug


func _ready() -> void:
	emp_disabled.connect(try_emp_stun)



## ───────── Main Loop ─────────────────────────|
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_process_state(delta)
	move_and_slide()
	_update_debug()

## ───────── STATE MACHINE ─────────
func _process_state(delta: float) -> void:
	match _state:
		State.IDLE:
			velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)
			if _should_chase():
				enter_state(State.CHASE)

		State.MOVE:
			_patrol_ground(delta)
			if _should_chase():
				enter_state(State.CHASE)

		State.STUNNED:
			pass

		State.CHASE:
			_chase_player(delta)
			if !_should_chase():      
				enter_state(State.MOVE)  
		
		State.ATTACK:
			velocity = Vector2.ZERO
		
		State.WIND_UP:
			velocity = Vector2.ZERO

func enter_state(new_state: int) -> void:
	if _state == new_state:
		return

	state_changed.emit(new_state)

	_state = new_state

	_windup_started = false

	match new_state:
		State.IDLE:
			sprite.play("Idle")
		State.MOVE:
			sprite.play("Moving")
		State.STUNNED:
			sprite.play("Stunned")
		State.CHASE:
			sprite.play("Moving") 
		State.ATTACK:
			sprite.play("Attack") 
		State.WIND_UP:
			# sprite.play("WindUp")   # optional
			if not _windup_started:
				_windup_started = true
				call_deferred("_wind_up_logic")



## ───────── EMP Stun Trigger ─────────
func try_emp_stun(duration):
	var tween = create_tween()
	tween.tween_callback(func():_state = State.STUNNED)
	tween.chain().tween_interval(duration)
	tween.chain().tween_callback(func():_state = State.MOVE)


#Temp debug lable. 
func _update_debug() -> void:
	debug.text = ["Idle", "Move", "Stunned", "Chase", "Attack", "Winding Up"][_state]



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
	ray_front.force_raycast_update() 
	ray_down.force_raycast_update() 
	
	sprite.flip_h = _move_dir > 0  ## [ > ] not [ < ]     


func _should_turn() -> bool:
	var should_turn := ray_front.is_colliding() or not ray_down.is_colliding()
	if should_turn:
		push_warning("Turn — front:", ray_front.is_colliding(),
		"  ground:", ray_down.is_colliding())
		return true
	else:
		return false


## ────────── CHASE LOGIC ─────────
func _should_chase() -> bool:
	var vision_hit = null
	if vision.is_colliding():
		vision_hit = vision
	elif vision_2.is_colliding():
		vision_hit = vision_2

	if vision_hit:
		var body = vision_hit.get_collider()
		if body is Node2D:
			_target_position = body.global_position
		else:
			_target_position = vision_hit.get_collision_point()

		return body.is_in_group("Player")
	
	return false

func _chase_player(delta: float) -> void:
	if _should_chase():
		var to_target := _target_position - global_position
		var distance = clamp(to_target.length(), 0.0, 400.0)
		var dir := to_target.normalized()

		var perpendicular := Vector2(-dir.y, dir.x)
		var dynamic_offset = perpendicular * target_offset.x * distance

		# Fade offset when close
		if distance < attack_range * 2:
			dynamic_offset *= distance / (attack_range * 2)

		var offset_target = _target_position + dynamic_offset
		var desired = (offset_target - global_position).normalized() * max_speed
		velocity = velocity.move_toward(desired, accel * delta)

		# Direction flip
		var new_dir = sign(to_target.x)
		if new_dir != _move_dir:
			_move_dir = new_dir
			sprite.flip_h = _move_dir > 0
			_update_vision_targets()
			_flip_rays()

		# ✅ Check distance to *actual* player position
		if global_position.distance_to(_target_position) < attack_range:
			print("✅ ATTACK RANGE REACHED!")
			enter_state(State.ATTACK)
			_target_position = Vector2.ZERO
	else:
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta)


func _wind_up_logic() -> void:
	if _state != State.WIND_UP:
		return

	velocity = Vector2.ZERO 

	await get_tree().create_timer(wind_up_delay).timeout

	if _state != State.WIND_UP:
		return

	if _should_chase() and global_position.distance_to(_target_position) < attack_range:
		enter_state(State.ATTACK)
	else:
		enter_state(State.MOVE)


func _update_vision_targets() -> void:
	vision.target_position.x   = abs(vision.target_position.x) * _move_dir
	vision_2.target_position.x = abs(vision_2.target_position.x) * -_move_dir

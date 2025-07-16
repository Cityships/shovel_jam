class_name Turret
extends Node2D

## ────────── NODES ──────────
@onready var head         : AnimatedSprite2D = %VisualTreeRoot
@onready var turret_area  : Area2D   = %TurretArea
@onready var ray          : RayCast2D = %Ray
@onready var charge_timer : Timer    = %ChargeTime
@onready var reload_timer : Timer    = %ReloadTime
@onready var label        : Label    = %Label

## ────────── CONSTANTS / ENUM ──────────
enum State { PATROL, CHARGE, SHOOT, IDLE }

var _patrol_base_y   : float   
var state            : int    = State.PATROL
var target           : Node2D = null
var charging         : bool   = false
var _patrol_base_rot : float  


## ────────── SIGNALS ──────────
signal state_changed(new_state : int)
signal emp_disabled(duration   : float)

## ────────── EXPORT  ──────────
@export var turn_speed           : float = 180.0
@export var patrol_pan_angle_deg : float = 45.0   ## how far to pan left/right
@export var patrol_pan_speed     : float = 1.2     ## radians-per-second
@export var patrol_center_angle_deg := 0.0 
@export var enemy_resource: EnemyResource
## ────────── READY ──────────
func _ready() -> void:
	_patrol_base_rot = deg_to_rad(patrol_center_angle_deg)
	turret_area.body_entered.connect(_on_body_entered)
	turret_area.body_exited.connect(_on_body_exited)
	charge_timer.timeout.connect(_on_charge_timeout)
	reload_timer.timeout.connect(_on_reload_timeout)
	emp_disabled.connect(_on_emp_disabled)
	_update_label()


## ────────── PROCESS ──────────
func _process(_delta: float) -> void:
	if target and state != State.PATROL:
		head.look_at(target.global_position)
	if state == State.PATROL:
		var t      = Time.get_ticks_msec() * 0.001
		var offset = sin(t * TAU * patrol_pan_speed) * deg_to_rad(patrol_pan_angle_deg)
		head.rotation = _patrol_base_rot + offset

## ────────── STATE HELPERS ──────────
func _set_state(new_state: int) -> void:
	if state == new_state: return
	state = new_state
	_update_label()
	state_changed.emit(state)

func _update_label() -> void:
	label.text = ["Patrol", "Charge", "Shoot", "Idle"][state]

## ────────── AREA CALLBACKS ──────────
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		target = body
		_set_state(State.CHARGE)
		_start_charging()

func _on_body_exited(body: Node) -> void:
	if body == target:
		target = null
		_stop_charging()
		_set_state(State.PATROL)

## ────────── CHARGE / RELOAD ──────────
func _start_charging() -> void:
	if charging: return
	charging = true
	charge_timer.start()

func _stop_charging() -> void:
	charging = false
	charge_timer.stop()

func _on_charge_timeout() -> void:
	if !charging or target == null: return
	_stop_charging()
	_set_state(State.SHOOT)
	head.shoot_laser()
	reload_timer.start()

func _on_reload_timeout() -> void:
	if target:
		_set_state(State.CHARGE)
		_start_charging()
	else:
		_set_state(State.PATROL)
		
		

## ────────── Patrol  ──────────

func _patrol_start()->void:
	pass

## ────────── EMP STUN (lambda + tween) ──────────
func _on_emp_disabled(duration: float) -> void:
	print("Signal Reached")
	_stop_charging()
	_set_state(State.IDLE)

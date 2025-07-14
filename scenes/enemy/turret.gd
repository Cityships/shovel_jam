class_name Turret
extends Node2D

## ────────── NODES ──────────
@onready var head         : Sprite2D = $TurretHead
@onready var turret_area  : Area2D   = %TurretArea
@onready var ray          : RayCast2D = %Ray
@onready var charge_timer : Timer    = %ChargeTime  
@onready var reload_timer : Timer    = %ReloadTime 
@onready var label        : Label    = %Label



##  ────────── CONSTANTS / ENUM ──────────
enum State { PATROL, CHARGE, SHOOT }
var state : int = State.PATROL  
var target : Node2D = null
var charging : bool = false                

##  ────────── EXPORT VARIABLES ──────────
@export var turn_speed : float = 180.0      # not used yet, future proof


## ────────── UNITY STYLE LIFECYCLE ──────────
func _ready() -> void:
	turret_area.body_entered.connect(_on_body_entered)
	turret_area.body_exited .connect(_on_body_exited)
	charge_timer.timeout.connect(_on_charge_timeout)
	reload_timer.timeout.connect(_on_reload_timeout)
	_update_label()

func _process(_delta: float) -> void:
	if target:
		head.look_at(target.global_position)

## ────────── STATE CHANGE HELPER ──────────
func _set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	_update_label()

func _update_label():
	label.text = ["Patrol", "Charge", "Shoot"][state]

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

## ────────── CHARGE / RELOAD LOGIC ──────────
func _start_charging():
	if charging:
		return
	charging = true
	charge_timer.start()               # uses Wait Time set in Inspector

func _stop_charging():
	charging = false
	charge_timer.stop()

func _on_charge_timeout() -> void:
	if not charging or target == null:
		return
	_stop_charging()
	_set_state(State.SHOOT)
	head.shoot_laser()
	reload_timer.start()               # Wait Time set in Inspector

func _on_reload_timeout() -> void:
	if target == null:
		_set_state(State.PATROL)
		return
	_set_state(State.CHARGE)
	_start_charging()

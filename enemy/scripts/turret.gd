## Turret Controller
##
## Finite‑state machine that controls an automated turret. Responsibilities:
##  • **Patrol**: sweeps left ↔ right while searching for a target.
##  • **Charge**: when a target is detected, counts down a charge‑up delay.
##  • **Shoot**: triggers the `shoot_laser()` method on the turret head.
##  • **Idle**: temporary stun / EMP state in which all action stops.
##
## The turret exposes signals so external systems (e.g. UI, hit effects)
## can react to state changes or EMP disables.
##
## **Node setup requirements**
## Attach this script to a **Node2D** that contains:
##  • **AnimatedSprite2D  "VisualTreeRoot"** – visual sprite; must have a
##    `shoot_laser()` method (e.g. the Laser script created earlier).
##  • **Area2D           "TurretArea"**    – detection collider; should have
##    its collision layer / mask set to detect the player group.
##  • **RayCast2D        "Ray"**           – optional; unused here but
##    exposed if you want to debug the LOS.
##  • **Timer "ChargeTime"** – delay before firing once target acquired.
##  • **Timer "ReloadTime"** – cooldown before next shot.
##  • **Label "Label"** – runtime debug label showing current state.
##
## Godot version: 4.4.1

class_name Turret
extends Node2D

#───────────────────────────────────────────────────────────────────────────────
## Child nodes
#───────────────────────────────────────────────────────────────────────────────
@onready var head         : AnimatedSprite2D = %VisualTreeRoot ## Rotates / shoots.
@onready var turret_area  : Area2D          = %TurretArea     ## Player detection.
@onready var ray          : RayCast2D       = %Ray            ## (Optional) LOS check.
@onready var charge_timer : Timer           = %ChargeTime     ## Charge‑up timer.
@onready var reload_timer : Timer           = %ReloadTime     ## Reload / cooldown.
@onready var label        : Label           = %Label          ## Debug state read‑out.

#───────────────────────────────────────────────────────────────────────────────
## State machine
#───────────────────────────────────────────────────────────────────────────────
## Enumeration of turret states.
enum State { PATROL, CHARGE, SHOOT, IDLE }

var state            : int      = State.PATROL ## Current FSM state.
var target           : Node2D   = null         ## Current target (player).
var charging         : bool     = false        ## True while charge_timer active.
var _patrol_base_rot : float    = 0.0          ## Center angle for patrol sweep.

#───────────────────────────────────────────────────────────────────────────────
## Signals
#───────────────────────────────────────────────────────────────────────────────
signal state_changed(new_state : int)          ## Emitted on every state change.
signal emp_disabled(duration   : float)        ## External EMP stun trigger.

#───────────────────────────────────────────────────────────────────────────────
# Exported properties
#───────────────────────────────────────────────────────────────────────────────
@export var turn_speed             : float = 180.0 ## deg/sec when manually rotating.
@export var patrol_pan_angle_deg   : float = 45.0  ## ±angle relative to center.
@export var patrol_pan_speed       : float = 1.2   ## Hz of sinusoid sweep.
@export var patrol_center_angle_deg: float = 0.0   ## Default facing angle.
@export var enemy_resource         : EnemyResource ## Reference to data asset.
@export var shoot_on_sight         : bool  = true  ## Fire immediately on detect.

#───────────────────────────────────────────────────────────────────────────────
## Ready
#───────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	## Cache patrol origin in radians.
	_patrol_base_rot = deg_to_rad(patrol_center_angle_deg)

	## Connect dynamic signals.
	turret_area.body_entered.connect(_on_body_entered)
	turret_area.body_exited.connect(_on_body_exited)
	charge_timer.timeout.connect(_on_charge_timeout)
	reload_timer.timeout.connect(_on_reload_timeout)
	emp_disabled.connect(_on_emp_disabled)

	_update_label()

#───────────────────────────────────────────────────────────────────────────────
## Process loop
#───────────────────────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	## Track target while in CHARGE / SHOOT state.
	if target and state != State.PATROL:
		head.look_at(target.global_position)

	## Patrol sweep: sinusoidal left‑right rotation around base angle.
	if state == State.PATROL:
		var t      = Time.get_ticks_msec() * 0.001
		var offset = sin(t * TAU * patrol_pan_speed) * deg_to_rad(patrol_pan_angle_deg)
		head.rotation = _patrol_base_rot + offset

#───────────────────────────────────────────────────────────────────────────────
## State helpers
#───────────────────────────────────────────────────────────────────────────────
func _set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	_update_label()
	state_changed.emit(state)

func _update_label() -> void:
	label.text = ["Patrol", "Charge", "Shoot", "Idle"][state]

#───────────────────────────────────────────────────────────────────────────────
## Detection callbacks
#───────────────────────────────────────────────────────────────────────────────
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

#───────────────────────────────────────────────────────────────────────────────
## Charge / reload logic
#───────────────────────────────────────────────────────────────────────────────
func _start_charging() -> void:
	if charging:
		return
	charging = true
	charge_timer.start()


func _stop_charging() -> void:
	charging = false
	charge_timer.stop()


func _on_charge_timeout() -> void:
	## Timer finished – try to fire.
	if not charging or target == null:
		return

	var fired = await head.shoot_laser()   ## <- await because shoot_laser() is async
	if not fired:
		return                               ## still on internal lock (very tiny chance)

	_stop_charging()                        ## exit charge state
	_set_state(State.SHOOT)                 ## play shoot animation, etc.
	reload_timer.start()                    ## begin full cooldown


func _on_reload_timeout() -> void:
	## Cooldown finished – re‑arm gun and possibly start new charge
	head.reset_cooldown()

	## Decide what to do next
	if _should_attack_again():
		_set_state(State.CHARGE)
		_start_charging()
	else:
		_set_state(State.IDLE)   ## or MOVE / PATROL, etc.


func _should_attack_again() -> bool:
	return target != null \
		and global_position.distance_to(target.global_position) 
#───────────────────────────────────────────────────────────────────────────────
## Patrol helpers (placeholder)
#───────────────────────────────────────────────────────────────────────────────
func _patrol_start() -> void:
	pass ## Extend for advanced patrol behaviours if needed.

#───────────────────────────────────────────────────────────────────────────────
## EMP stun
#───────────────────────────────────────────────────────────────────────────────
func _on_emp_disabled(duration: float) -> void:
	## External callers can emit `emp_disabled` to force the turret idle.
	_stop_charging()
	_set_state(State.IDLE)
	## Forward the effect to the head for visuals (flicker, grayscale, etc.).
	head.play_emp_disable(duration)

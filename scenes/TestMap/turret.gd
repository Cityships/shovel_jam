class_name Turret
extends Node2D

@onready var head := $TurretHead
@export  var turn_speed : float = 180.0  
@onready var charge_timer: Timer = %ChargeTime
@onready var turret_area: Area2D = %TurretArea
@onready var ray: RayCast2D = %Ray
@onready var label: Label = %Label
@onready var reload_time: Timer = %ReloadTime

var target : Node2D = null
var charging:bool = false 
var charge: int = 0
const MAX_CHARGE = 100

@export_enum("Patrol", "Charge", "Shoot") var turret_state = 0

var text = str(turret_state)
func _ready() -> void:
	turret_area.body_entered.connect(_on_body_entered)
	turret_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		target = body
		_state_change(1)
		print(turret_state)

func _on_body_exited(body: Node) -> void:
	if body == target:
		target = null

func _process(_delta: float) -> void:
	label.set_text(text)
	if target == null:
		return

	head.look_at(target.global_position) 


func _state_change(new_state: int):
	if new_state == 1:
		turret_state = new_state
		start_charging()
		print("Charging")
	if new_state == 2:
		head.shoot_laser()
		if target == null:
			turret_state = 0
		reload_time.start(1.0)
		print("pewww")
		

func start_charging():
	charge   = 0
	charging = true
	charge_timer.start()
	print(charge_timer)             # first tick

func stop_charging():
	charging = false
	charge_timer.stop()


func _on_charge_time_timeout() -> void:
	if not charging:
		return
	_state_change(2)
	


func _on_reload_time_timeout() -> void:
	start_charging()

extends Node2D

enum KeyType {STANDARD, LIGHT, REMOTE}

signal key_type_changed
signal key_rotation

@export var key_type : KeyType = KeyType.STANDARD
@export var charge_per_rotation : float = 20
@onready var turn_key : Node2D = %TurnKey
@onready var recharge_area : Area2D = get_node("RechargeArea")
@onready var sprite_2d : Sprite2D = get_node("Sprite2D")

var current_rotation : float
var rotation_ticks : int = 0
var last_mouse_velocity : float
var tween
var mouse_over : bool = false

var current_controls : int = -1#-1 gadget options, 1 key options

func _ready() -> void:
	turn_key.get_node("KeyArea").mouse_entered.connect(func(): mouse_over = true)
	key_rotation.connect(recharge)

	recharge_area.body_entered.connect(func(_value): visible = true)
	recharge_area.body_exited.connect(func(_value): if recharge_area.get_overlapping_areas().size() == 0: visible = false)

	key_type_changed.connect(
		func():
			if key_type == KeyType.STANDARD:
				self.modulate = Color.BLUE
				recharge_area.get_node("CollisionShape2D").shape.radius = 32
				recharge_area.force_update_transform()
			if key_type == KeyType.LIGHT:
				self.modulate = Color.YELLOW
				recharge_area.get_node("CollisionShape2D").shape.radius = 32
				recharge_area.force_update_transform()
			if key_type == KeyType.REMOTE:
				recharge_area.get_node("CollisionShape2D").shape.radius = 120
				self.modulate = Color.RED
				recharge_area.force_update_transform()
	)

	GlobalEvents.control_option_switch.connect(
		func(value):
			current_controls = value
			if value == 1: 
				GlobalEvents.create_quick_tip.emit(get_parent().global_position, "Keys Selected!")
	)

func _process(delta: float) -> void:
	if rotation_ticks > 0 and key_type == KeyType.LIGHT and last_mouse_velocity > 0:
		if last_mouse_velocity < 0.5:
			last_mouse_velocity = 0
			key_rotation.emit(rotation_ticks * 30 / 360.0)
			rotation_ticks = 0
			return
		last_mouse_velocity = lerp(last_mouse_velocity, 0.0, delta)
		turn_key.rotation += delta * last_mouse_velocity
		

func _input(_event: InputEvent) -> void:

	if Input.is_key_pressed(KEY_1) and current_controls == 1:
		key_type = KeyType.STANDARD
		key_type_changed.emit()
	elif Input.is_key_pressed(KEY_2) and current_controls == 1:
		key_type = KeyType.LIGHT
		key_type_changed.emit()
	elif Input.is_key_pressed(KEY_3) and current_controls == 1:
		key_type = KeyType.REMOTE
		key_type_changed.emit()

	if mouse_over and Input.is_action_pressed("left_mouse_button"):
		var mouse_position = get_local_mouse_position()
		turn_key.rotation = atan2(mouse_position.y, mouse_position.x)
		if turn_key.rotation_degrees < 0:
			if current_rotation > 0:
				current_rotation = -180
			elif turn_key.rotation_degrees > current_rotation + 30:
				rotation_ticks += 1
				current_rotation += 30
		elif turn_key.rotation_degrees > 0:
			if current_rotation < 0:
					current_rotation = 0
			elif turn_key.rotation_degrees > current_rotation + 30:
				rotation_ticks += 1
				current_rotation += 30
			
	if mouse_over and Input.is_action_just_pressed("left_mouse_button"):
		last_mouse_velocity = 0
		current_rotation = turn_key.rotation_degrees

	if Input.is_action_just_released("left_mouse_button") and rotation_ticks > 0:
		if key_type == KeyType.LIGHT:
			last_mouse_velocity = Input.get_last_mouse_velocity().length()/180
		if key_type == KeyType.STANDARD or key_type == KeyType.REMOTE:
			key_rotation.emit(rotation_ticks * 30 / 360.0)	
			rotation_ticks = 0
		mouse_over = false
		
func recharge(rotations : float):
	print("wind_up_gizmo.gd: charging nearby toys - ", rotations * charge_per_rotation)
	for body in recharge_area.get_overlapping_bodies():
		if body.has_method("recharge"):
			body.recharge(rotations * charge_per_rotation)
		else:
			print("wind_up_gizmo.gd: ", body.name, " does not have a recharge function")

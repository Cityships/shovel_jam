extends Node2D

enum KeyType {STANDARD, LIGHT, RETAIN}

signal key_type_changed
signal try_recharge

@export var key_type : KeyType = KeyType.STANDARD
@export var charge_per_rotation : float = 20
@onready var turn_key : Node2D = %TurnKey
@onready var recharge_area : Area2D = get_node("RechargeArea")
@onready var sprite_2d : Sprite2D = get_node("Sprite2D")
@onready var audio_stream : AudioStreamPlayer2D = get_node("AudioStreamPlayer2D")

var current_rotation : float
var rotation_ticks : int = 0
var last_mouse_velocity : float
var delayed_recharge_list = []:
	set(value):
		delayed_recharge_list = value
		if value.is_empty() and key_type == KeyType.LIGHT:
			sprite_2d.material.set_shader_parameter("outline_enabled", false)
var delayed_recharge_rotations : float

var standard_key_stored_energy : float

var tween
var mouse_over : bool = false

var current_controls : int = -1#-1 gadget options, 1 key options

func _ready() -> void:

	sprite_2d.material = sprite_2d.material.duplicate()
	sprite_2d.material.set_shader_parameter("outline_enabled", false)

	turn_key.get_node("KeyArea").mouse_entered.connect(func(): mouse_over = true)
	try_recharge.connect(recharge)

	recharge_area.body_entered.connect(
		func(value):
			sprite_2d.material.set_shader_parameter("outline_enabled", true)
			if get_parent().is_on_floor():
				try_recharge.emit(standard_key_stored_energy)
				standard_key_stored_energy = 0
	)
	recharge_area.body_exited.connect(
		func(_value):
			if key_type == KeyType.LIGHT and delayed_recharge_list.size() != 0:
				return
			if recharge_area.get_overlapping_areas().size() == 0:
				sprite_2d.material.set_shader_parameter("outline_enabled", false)
	)

	key_type_changed.connect(
		func():
			if key_type == KeyType.STANDARD:
				self.modulate = Color.BLUE
				recharge_area.get_node("CollisionShape2D").shape.radius = 80
				recharge_area.force_update_transform()
			if key_type == KeyType.LIGHT:
				self.modulate = Color.YELLOW
				recharge_area.get_node("CollisionShape2D").shape.radius = 64
				recharge_area.force_update_transform()
			if key_type == KeyType.RETAIN:
				recharge_area.get_node("CollisionShape2D").shape.radius = 32
				self.modulate = Color.RED
				recharge_area.force_update_transform()
	)
	key_type_changed.emit()

	GlobalEvents.control_option_switch.connect(
		func(value):
			current_controls = value
			if value == 1: 
				GlobalEvents.create_quick_tip.emit(get_parent().global_position, "Keys Selected!")
				visible = true
			if value == -1:
				visible = false
	)

func _process(delta: float) -> void:
	if rotation_ticks > 0 and key_type == KeyType.LIGHT and last_mouse_velocity > 0:
		if last_mouse_velocity < 0.5:
			last_mouse_velocity = 0
			try_recharge.emit(rotation_ticks * 30 / 360.0)
			rotation_ticks = 0
			for body in delayed_recharge_list:
				if body.has_method("recharge"):
					body.recharge(delayed_recharge_rotations * charge_per_rotation)
					body.auto_trigger.emit()
		last_mouse_velocity = lerp(last_mouse_velocity, 0.0, delta)
		turn_key.rotation += delta * last_mouse_velocity
		

func _input(_event: InputEvent) -> void:

	if Input.is_key_pressed(KEY_1) and current_controls == 1 and !mouse_over:
		key_type = KeyType.STANDARD
		key_type_changed.emit()
	elif Input.is_key_pressed(KEY_2) and current_controls == 1 and !mouse_over:
		key_type = KeyType.LIGHT
		key_type_changed.emit()
	elif Input.is_key_pressed(KEY_3) and current_controls == 1 and !mouse_over:
		key_type = KeyType.RETAIN
		key_type_changed.emit()

	if key_type == KeyType.LIGHT and last_mouse_velocity != 0:
		return

	if key_type == KeyType.RETAIN and recharge_area.get_overlapping_bodies().size() == 0 and recharge_area.get_overlapping_areas().size() == 0:
		return

	if mouse_over and Input.is_action_pressed("left_mouse_button"):

		var mouse_position = get_local_mouse_position()
		turn_key.rotation = atan2(mouse_position.y, mouse_position.x)
		if turn_key.rotation_degrees < 0:
			if current_rotation > 0:
				current_rotation = -180
			elif turn_key.rotation_degrees > current_rotation + 30:
				rotation_ticks += 1
				current_rotation += 30
				if key_type == KeyType.STANDARD:
					try_recharge.emit(30 / 360.0)
		elif turn_key.rotation_degrees > 0:
			if current_rotation < 0:
				current_rotation = 0
			elif turn_key.rotation_degrees > current_rotation + 30:
				rotation_ticks += 1
				current_rotation += 30
				if key_type == KeyType.STANDARD:
					try_recharge.emit(30 / 360.0)
		if fmod(rotation_ticks, 6) == 0 and !audio_stream.playing:
			audio_stream.play()
			
	if mouse_over and Input.is_action_just_pressed("left_mouse_button"):
		last_mouse_velocity = 0
		current_rotation = turn_key.rotation_degrees

	if Input.is_action_just_released("left_mouse_button") and rotation_ticks > 0:
		if key_type == KeyType.LIGHT:
			last_mouse_velocity = Input.get_last_mouse_velocity().length()/180
			for body in recharge_area.get_overlapping_bodies():
				if key_type == KeyType.LIGHT:
					delayed_recharge_list.append(body)
					delayed_recharge_rotations = rotation_ticks * 30 / 360.0
		if key_type == KeyType.RETAIN:
			try_recharge.emit(rotation_ticks * 30 / 360.0)	
			rotation_ticks = 0
		mouse_over = false
		
func recharge(rotations : float):
	var bodies = recharge_area.get_overlapping_bodies()
	if bodies.is_empty() and key_type == KeyType.STANDARD:
		standard_key_stored_energy += rotations
	for body in bodies:
		if key_type == KeyType.LIGHT:
			return
		if key_type == KeyType.RETAIN:
			body.force_recharge(rotations * charge_per_rotation + last_mouse_velocity * 0.01)
		if body.has_method("recharge"):
			body.recharge(rotations * charge_per_rotation)
		else:
			print("wind_up_gizmo.gd: ", body.name, " does not have a recharge function")

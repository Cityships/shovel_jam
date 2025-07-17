extends CharacterBody2D

var speed: float = 105.0
var acceleration: float = 630.0
var jump_velocity: float = -310.0
var gravity := Vector2(0, 980)
var input_direction := Vector2.ZERO

var movement_restriction_count = 0

@onready var sprite = get_node("Sprite2D")
@onready var gadget_area :Area2D = get_node("GadgetArea")
var current_controls : int = -1 ##1 gadget options, 2 key options

func _ready() -> void:
	GlobalEvents.control_option_switch.connect(
		func(value):
			current_controls = value
			if value == -1: 
				GlobalEvents.create_quick_tip.emit(global_position, "Gadgets Selected!")
	)
	pass

func _physics_process(delta: float) -> void:
	if movement_restriction_count != 0:
		return
	apply_gravity(delta)
	move()
	_set_sprite_direction()
	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += gravity * delta

func move() -> void:
	velocity.x = move_toward(
		velocity.x, input_direction.x * speed,
		acceleration * get_physics_process_delta_time()
	)
	if input_direction.y > 0 and is_on_floor():
		velocity.y = jump_velocity

func _set_sprite_direction() -> void:
	if input_direction.x:
		sprite.flip_h = input_direction.x == 1
		gadget_area.position.x = input_direction.x * 32
	

func _input(_event: InputEvent) -> void:
	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_down", "ui_up")

	if Input.is_action_just_pressed("pick_up_gadget"):
		var collision = gadget_area.get_overlapping_bodies()
		for object in collision:
			if object is Gadget:
				GlobalEvents.request_pickup_gadget.emit(object)
	
	if Input.is_key_pressed(KEY_1) and current_controls == -1:
		GlobalEvents.request_deploy_gadget.emit(gadget_area.global_position, "Jetpack")
	if Input.is_key_pressed(KEY_2) and current_controls == -1:
		GlobalEvents.request_deploy_gadget.emit(gadget_area.global_position, "EmpObject")

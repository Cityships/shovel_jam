extends CharacterBody2D

@export var speed: float = 105.0
@export var acceleration: float = 630.0
@export var jump_velocity: float = -310.0

@export var movement_state=0

enum MovementState { IDLE, MOVE, AIM, FLY, ATTACK, WIND_UP, JUMP }
@export var _movement_state : MovementState = MovementState.IDLE   ## Initial state when the scene loads.


var gravity := Vector2(0, 980)
var input_direction := Vector2.ZERO
var movement_restriction_count = 0
var current_controls : int = -1 ##1 gadget options, 2 key options
var _can_jump:bool = true
@onready var sprite = get_node("Sprite2D")
@onready var gadget_area :Area2D = get_node("GadgetArea")
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
	
	if _movement_state == MovementState.JUMP and is_on_floor():
		_movement_state = MovementState.IDLE
		_can_jump       = true
		if sprite.animation != "Idle":
			sprite.play("Idle")

	if is_on_floor() and abs(velocity.x) < 0.01 and _movement_state != MovementState.JUMP:
		if _movement_state != MovementState.IDLE:
			_movement_state = MovementState.IDLE
			if sprite.animation != "Idle":
				sprite.play("Idle")


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += gravity * delta

func move() -> void:
	velocity.x = move_toward(
		velocity.x, input_direction.x * speed,
		acceleration * get_physics_process_delta_time()
		
	)
## ─── HORIZONTAL RUN ANIMATION ─────────────────────────────────────────
	if abs(velocity.x) > 0.01 and is_on_floor():
		if _movement_state != MovementState.MOVE:
			_movement_state = MovementState.MOVE
			if sprite.animation != "Moving":
				sprite.play("Moving")

	
	if !velocity.x == 0:
		if _movement_state == MovementState.JUMP:
			return
		sprite.play("Moving")
		_movement_state = MovementState.MOVE
	
	if input_direction.y > 0 and is_on_floor() and _can_jump:
		velocity.y = jump_velocity 
		_movement_state = MovementState.JUMP
		if sprite.animation != "Jump":
			sprite.play("Jump")
		_can_jump = false
		start_cooldown(1.0) 

func _set_sprite_direction() -> void:
	if input_direction.x:
		sprite.flip_h = input_direction.x == -1
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
		sprite.play("WindUp")
		print("emp")


func start_cooldown(seconds: float) -> void:
	var timer := Timer.new()
	timer.wait_time = seconds
	timer.one_shot  = true 
	add_child(timer) 
	timer.timeout.connect(_on_cooldown_timeout)
	timer.start()

func _on_cooldown_timeout() -> void:
	_can_jump = true

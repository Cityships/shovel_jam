extends CharacterBody2D

var speed: float = 105.0
var acceleration: float = 630.0
var jump_velocity: float = -310.0
var gravity := Vector2(0, 980)
var input_direction := Vector2.ZERO

var movement_restriction_count = 0

@onready var sprite = get_node("Sprite2D")

func _ready() -> void:

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

func _input(_event: InputEvent) -> void:
	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_down", "ui_up")

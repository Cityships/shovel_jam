extends RigidBody2D
class_name JetPack

@onready var interactable_area : Area2D = get_node("InteractableArea")
@onready var windup_progress_bar : ProgressBar = get_node("ProgressBar")

var input_direction : Vector2

var player
var hold_player : bool
@onready var player_area : CollisionShape2D = get_node("PlayerArea")

func _ready() -> void:
	interactable_area.body_entered.connect(func(value): player = value)
	interactable_area.body_exited.connect(
		func(value):
			value.movement_restriction_count = 0
			player = null
			hold_player = false
			player_area.set_deferred("disabled", true)
	)

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("ui_accept") and player != null:
		player.movement_restriction_count = 1
		hold_player = true
		player.reparent(self, true)
		player.position = round(player.position.normalized()) * 32
		if abs(player.position.y) == abs(player.position.x):
			player.position.y = 0
		player_area.position = player.position
		player_area.set_deferred("disabled", false)

	if Input.is_action_just_released("ui_accept") and hold_player:
		player.movement_restriction_count = 0
		hold_player = false
		player.reparent(get_parent())
		player_area.set_deferred("disabled", true)

	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_up", "ui_down")
	if hold_player:
		constant_force = input_direction * Vector2(0.25, 1.25)
	else:
		constant_force = Vector2.ZERO

extends AnimatableBody2D

signal emp_disabled

@onready var path_follow : PathFollow2D = get_parent()
@onready var gadget_door := get_parent().get_parent()
@onready var windup_progress_bar : ProgressBar = get_node("ProgressBar")
var door_opened = false

func open_door():
	var tween = create_tween()
	tween.tween_method(
		func(value):
			path_follow.progress_ratio = value,
		0.0, 1.0, 3
	)

func recharge(value):
	windup_progress_bar.value += value
	if windup_progress_bar.value == windup_progress_bar.max_value and !door_opened:
		windup_progress_bar.modulate = Color.GREEN
		open_door()
		gadget_door.door_open.emit()
		door_opened = true
	else:
		windup_progress_bar.modulate = Color.WHITE

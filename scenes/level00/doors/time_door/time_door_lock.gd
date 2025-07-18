extends StaticBody2D

signal auto_trigger

@onready var progress_bar :ProgressBar = get_node("ProgressBar")


func recharge(amount_rotations : float):
	progress_bar.value += amount_rotations
	if progress_bar.value == progress_bar.max_value:
		get_parent().door_locked = false
		get_parent().open_door(0)

func force_recharge(_amount_rotations : float):
	recharge(_amount_rotations)

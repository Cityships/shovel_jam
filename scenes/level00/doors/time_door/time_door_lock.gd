extends StaticBody2D

@onready var open_door
@onready var progress_bar :ProgressBar = get_node("ProgressBar")

func recharge(amount_rotations : float):
	progress_bar.value += amount_rotations	

func force_recharge(_amount_rotations : float):
	recharge(_amount_rotations)

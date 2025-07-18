extends Node

@onready var progress_bar = get_node("ProgressBar")

func recharge(amount_rotations : float):
	progress_bar.value += amount_rotations	

func force_recharge(_amount_rotations : float):
	recharge(_amount_rotations)

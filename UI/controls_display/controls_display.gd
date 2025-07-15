extends Control

@onready var tabs : TabContainer = %TabContainer

func _ready() -> void:
	GlobalEvents.control_option_switch.connect(func(value): tabs.current_tab = max(0, value))

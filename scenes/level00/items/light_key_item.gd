extends Node2D

@onready var area :Area2D = get_node("Area2D")

func _ready() -> void:
	area.body_entered.connect(func(_value): GlobalEvents.light_key_obtained(); print("light key obtained"); queue_free(),)

extends Node2D

@onready var area :Area2D = get_node("Area2D")
func _ready() -> void:
	area.body_entered.connect(func(_value): Globals.obtained_keys.append(2); GlobalEvents.key_obtained.emit(); queue_free(),)

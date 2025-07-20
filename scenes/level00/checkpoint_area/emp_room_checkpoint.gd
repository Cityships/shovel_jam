extends Area2D

@export var emp_node : Node2D

func _ready() -> void:
    body_entered.connect(
        func(_value):
            GlobalEvents.gadget_obtained.emit(emp_node)
            Globals.obtained_gadgets.append(emp_node),
    )
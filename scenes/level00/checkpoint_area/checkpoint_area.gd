extends Area2D

@export var skip_to_index: int = 0

func _ready() -> void:
    body_entered.connect(
        func(_value):
            GlobalEvents.story_bot_skip_to_index.emit(skip_to_index),
    )
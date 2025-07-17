extends AnimatableBody2D

@onready var path_follow : PathFollow2D = get_parent()
@export var story_index : int = 0

func _ready() -> void:
	GlobalEvents.story_bot_index_changed.connect(
		func(value):
			if value == story_index:
				open_door()
	)

func open_door():
	var tween = create_tween()
	tween.tween_method(
		func(value):
			path_follow.progress_ratio = value,
		0.0, 1.0, 3
	)

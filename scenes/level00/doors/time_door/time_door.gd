extends Path2D

@export var skip_to_index: int = -1

@onready var time_door_lock = get_node("TimeDoorLock")
@onready var room_enter : Area2D = get_node("RoomEnter")
@onready var room_inside : Area2D = get_node("RoomInside")
@onready var path_follow :PathFollow2D = get_node("PathFollow2D")

var door_opened: bool = false
var door_locked: bool = false

func _ready() -> void:
    room_enter.body_entered.connect(open_door)
    room_inside.body_entered.connect(
        func(_player):
            close_door()
            door_locked = true
            if skip_to_index != -1:
                GlobalEvents.story_bot_skip_to_index.emit(skip_to_index)
            GlobalEvents.set_checkpoint.emit(self.global_position),
    )

func close_door():
    if door_opened:
        door_opened = false
        var tween = create_tween()
        tween.tween_method(
            func(value):
                path_follow.progress_ratio = value,
            1.0, 0.0, 0.2
        ).set_trans(Tween.TRANS_QUAD)

func open_door(_value):
    if !door_opened and !door_locked:
        door_opened = true
        var tween = create_tween()
        tween.tween_method(
            func(value):
                path_follow.progress_ratio = value,
            0.0, 1.0, 0.2
        ).set_trans(Tween.TRANS_QUAD)
        tween.chain().tween_interval(1)
        tween.chain().tween_callback(
            func():
                if room_enter.get_overlapping_bodies().size() == 0:
                    door_locked = true
                    close_door()
        )


extends Path2D

@onready var path_follow = get_node("PathFollow2D")
@onready var door_lock0= get_node("DoorLock0")
@onready var progress_bar0 : ProgressBar = get_node("DoorLock0/ProgressBar")
@onready var door_lock1 = get_node("DoorLock1")
@onready var progress_bar1: ProgressBar = get_node("DoorLock1/ProgressBar")
@onready var door_lock2 = get_node("DoorLock2")
@onready var progress_bar2: ProgressBar = get_node("DoorLock2/ProgressBar")

var lock_0 : bool = true:
    set(value):
        lock_0 = value
        if !lock_0 and !lock_1 and !lock_2:
            open_door()
var lock_1 : bool = true:
    set(value):
        lock_1 = value
        if !lock_0 and !lock_1 and !lock_2:
            open_door()
var lock_2 : bool = true:
    set(value):
        lock_2 = value
        if !lock_0 and !lock_1 and !lock_2:
            open_door()

func _ready() -> void:
    progress_bar0.value_changed.connect(func(_value): if progress_bar0.value == progress_bar0.max_value: lock_0 = false)
    progress_bar1.value_changed.connect(func(_value): if progress_bar1.value == progress_bar0.max_value: lock_1 = false)
    progress_bar2.value_changed.connect(func(_value): if progress_bar2.value == progress_bar0.max_value: lock_2 = false,)

func open_door():
    print("open_door")
    var tween = create_tween()
    tween.tween_method(
        func(value):
            path_follow.progress_ratio = value,
        0.0, 1.0, 0.2
    ).set_trans(Tween.TRANS_QUAD)

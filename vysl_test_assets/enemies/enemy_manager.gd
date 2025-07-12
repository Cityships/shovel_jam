extends Path2D

var path_time : float = 10.0

func _ready() -> void:
    for child in get_children():
        if child is PathFollow2D:
            auto_path(child)

func auto_path(node : PathFollow2D):
    var tween = node.create_tween()
    tween.tween_method(
        func(value):
            node.progress_ratio = value,
        0.0, 1.0, path_time
    )
    tween.finished.connect(auto_path.bind(node))
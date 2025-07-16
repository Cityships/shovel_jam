extends AnimatableBody2D

signal emp_disabled

@onready var path_follow : PathFollow2D = get_parent()
@export var path_follow_speed : float = 0.5
var path_loop : bool
var current_path_follow_speed : float
var dir : Vector2 = Vector2(1,0)

var stop : bool = false

func _ready() -> void:
	emp_disabled.connect(try_emp_disable)
	path_loop = path_follow.loop

func _process(delta: float) -> void:
	if !stop:
		path_follow.progress_ratio += dir.x * path_follow_speed * delta
		if path_loop:
			pass
		elif fmod(path_follow.progress_ratio, 1) == 0:
			dir = -dir
		move_and_collide(dir*path_follow_speed*delta)

func try_emp_disable(duration):
	stop = true
	print("stop")
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.finished.connect(func(): stop = false,)
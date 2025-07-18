extends AnimatableBody2D

@onready var path_follow : PathFollow2D = get_parent()
@export var path_follow_speed : float = 0.5
var path_loop : bool
var current_path_follow_speed : float
var dir : Vector2 = Vector2(1,0)

func _ready() -> void:
	path_loop = path_follow.loop

func _process(delta: float) -> void:
	path_follow.progress_ratio += dir.x * path_follow_speed * delta
	if path_loop:
		pass
	elif fmod(path_follow.progress_ratio, 1) == 0:
		dir = -dir
	move_and_collide(dir*path_follow_speed*delta)

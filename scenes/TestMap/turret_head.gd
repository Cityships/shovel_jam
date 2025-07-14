extends Sprite2D

@onready var ray  : RayCast2D = %Ray
@onready var beam : Line2D    = %Beam

@export var max_distance   : float = 800.0
@export var flash_time     : float = 0.05
@export var cooldown_time  : float = 0.5
@export var damage         : int   = 10

var _ready_to_fire := true


func shoot_laser() -> void:
	if not _ready_to_fire:
		return

	_ready_to_fire = false
	ray.enabled    = true          # physics on (NO ray.visible!)
	ray.target_position = Vector2.RIGHT * max_distance
	ray.force_raycast_update()

	var hit_pos : Vector2

	if ray.is_colliding():
		hit_pos = ray.get_collision_point()
		var body = ray.get_collider()
		if body.has_method("apply_damage"):
			body.apply_damage(damage)
	else:
		hit_pos = global_position + global_transform.x * max_distance

	# draw the flashy beam only
	beam.points  = [Vector2.ZERO, beam.to_local(hit_pos)]
	beam.visible = true

	await get_tree().create_timer(flash_time).timeout
	beam.visible = false
	ray.enabled  = false           # stop querying until next shot

	await get_tree().create_timer(cooldown_time - flash_time).timeout
	_ready_to_fire = true

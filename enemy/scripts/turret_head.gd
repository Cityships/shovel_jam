extends AnimatedSprite2D

@onready var ray  : RayCast2D = %Ray
@onready var beam : Line2D    = %Beam

@export var max_distance   : float = 800.0
@export var flash_time     : float = 0.05
@export var cooldown_time  : float = 0.5
@export var damage         : int   = 10

var _ready_to_fire := true



func _ready() -> void:
	material = material.duplicate()

func set_solid_color(flag, color):## Necessary because modulate cannot override shaders.
	material.set_shader_parameter("fill_color", color)
	material.set_shader_parameter("fill_enabled", flag)

func set_grayscale(flag):
	material.set_shader_parameter("grayscale_enabled", flag)

func play_emp_disable(duration : float):
	var tween = create_tween()
	tween.tween_callback(set_grayscale.bind(true))
	tween.chain().tween_interval(0.50 * duration)
	tween.chain().tween_method(
		func(value):
			if fmod(value, 2) == 0:
				set_solid_color(true, Color.WHITE)
			else:
				set_solid_color(false, Color.WHITE),
		0, 4, 0.25 * duration
	)
	tween.chain().tween_method(
		func(value):
			if fmod(value, 2) == 0:
				set_solid_color(true, Color.WHITE)
			else:
				set_solid_color(false, Color.WHITE),
		5, 15, 0.25 * duration
	)
	tween.chain().tween_callback(set_solid_color.bind(false, Color.WHITE))
	tween.chain().tween_callback(set_grayscale.bind(false))

func shoot_laser() -> void:
	if not _ready_to_fire:
		return

	_ready_to_fire = false
	ray.enabled    = true      
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


	beam.points  = [Vector2.ZERO, beam.to_local(hit_pos)]
	beam.visible = true

	await get_tree().create_timer(flash_time).timeout
	beam.visible = false
	ray.enabled  = false

	await get_tree().create_timer(cooldown_time - flash_time).timeout
	_ready_to_fire = true

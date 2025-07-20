extends AnimatedSprite2D

func _ready() -> void:
	material = material.duplicate()

func set_solid_color(flag, color):#Necessary because modulate cannot override shaders.
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

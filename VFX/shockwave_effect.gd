extends Sprite2D

@export var shockwave_radius_curve : Curve
@export var force_curve : Curve
@export var starting_force : float = 0.35
@export var life_time : float = 0.8
var mat

func _ready() -> void:
	visible = false
	material = material.duplicate()
	mat = material
	mat.set_shader_parameter("size", 0.0)

func play_animation():
	var tween = create_tween()
	tween.tween_callback(
		func(): 
			mat.set_shader_parameter("mark_thickness", 0.01)
			#mat.set_shader_parameter("force", starting_force)
			visible = true
	)
	tween.chain().tween_method(
		func(value):
			mat.set_shader_parameter("size", shockwave_radius_curve.sample(value) * 2)
			mat.set_shader_parameter("force", force_curve.sample(value)),
		0.0, 1.0, life_time
	)
	tween.chain().tween_callback(func():visible = false)
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		play_animation()

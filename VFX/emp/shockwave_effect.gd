@tool
extends Node2D

@export_group("Shockwave animation controls")
@export var shockwave_radius_curve : Curve
@export_range(0, 0.5) var shockwave_max_radius : float = 0.5
#note that the max size can cause the shockwave circle to clip the sprite borders
@export var force_curve : Curve
@export var starting_force : float = 0.35
@export var life_time : float = 0.8
@export var mark_gradient : Gradient
@onready var shockwave_sprite = get_node("EmpSprite2D")
var shockwave_mat

@export_group("Additional visual effects")
@export var flash_gradient : Gradient
#This Canvas layer is obviously bad practice, when we get about to creating global signals
#then we will adjust this to a canvas item that listens to a global event
@onready var color_rect : ColorRect = get_node("CanvasLayer/ColorRect")

#area of effect
@export_group("Main")
@export var emp_radius : float = 144.0
@export var effect_duration : float = 4.0
@export var CALLED_METHOD_NAME : StringName = "play_emp_disable":
	set(value):
		#This is the name of the effect that will be called when
		pass
@onready var area_2d : Area2D = get_node("Area2D")

func _ready() -> void:
	shockwave_sprite.visible = false
	shockwave_sprite.material = shockwave_sprite.material.duplicate()
	shockwave_mat = shockwave_sprite.material

func play_animation():
	var emp_tween = create_tween()
	emp_tween.tween_callback(func(): shockwave_sprite.visible = true)
	emp_tween.chain().tween_method(
		func(value):
			shockwave_mat.set_shader_parameter("size", shockwave_radius_curve.sample(value) * shockwave_max_radius)
			shockwave_mat.set_shader_parameter("force", force_curve.sample(value) * shockwave_max_radius)
			shockwave_mat.set_shader_parameter("mark_color", mark_gradient.sample(value))
			color_rect.color = flash_gradient.sample(value),
		0.0, 1.0, life_time
	)
	emp_tween.chain().tween_callback(func(): shockwave_sprite.visible = false)

	var detection = create_tween()
	detection.tween_interval(0.1)
	detection.tween_callback(
		func():
			#DEBUG body or area2d needs to be detected?
			for body in area_2d.get_overlapping_bodies():
				body.get_node("VisualTreeRoot").play_emp_disable(6)
				body.emp_disabled.emit(6)
			#HERE
			for area in area_2d.get_overlapping_areas():
				area.get_parent().get_node("VisualTreeRoot").play_emp_disable(6)
				area.emp_disabled.emit(6)
	)
#Test the animation for yourself!
func _input(event: InputEvent) -> void:
	pass
	#if Input.is_action_just_pressed("ui_accept"):
	#	play_animation()

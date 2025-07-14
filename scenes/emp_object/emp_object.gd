extends RigidBody2D

@onready var arc_indicator : Line2D = get_node("ArcIndicator")
@export var max_throw_radius : float = 128
@export var bezier_resolution : int = 16
@export var emp_explosion_effect : PackedScene
var emp_instance

@onready var interactable_area : Area2D = get_node("InteractableArea")
@onready var windup_progress_bar : ProgressBar
@export var throw_force_multiplier : float = 100
var player
var armed_emp : bool

@onready var scene = get_parent()

func _ready() -> void:
	emp_instance = emp_explosion_effect.instantiate()
	add_child(emp_instance)
	interactable_area.body_entered.connect(func(value): player = value)
	interactable_area.body_exited.connect(func(_value): player = null)

func recharge(value):
	windup_progress_bar.value += value

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept") and player != null:
		freeze = true
		reparent(player)
		self.position = Vector2(0,-32)
		armed_emp = true
	if Input.is_action_just_released("ui_accept") and armed_emp:
		freeze = false
		reparent(scene, true)
		armed_emp = false
		self.apply_force((get_global_mouse_position() - global_position) * throw_force_multiplier)
		var tween = create_tween()
		tween.tween_interval(2)
		tween.chain().tween_callback(func():emp_instance.play_animation())
	return

	#region EXPERIMENTAL PLOT TRAJECTORY
	if Input.is_action_just_pressed("ui_accept"):
		arc_indicator.add_point(Vector2.ZERO, 0)
		for i in bezier_resolution:
			arc_indicator.add_point(Vector2.ZERO, i)
	if Input.is_action_pressed("ui_accept"):
		set_arc_indicator()
	if Input.is_action_just_released("ui_accept"):
		arc_indicator.clear_points()
	#endregion

#region EXPERIMENTAL PLOT TRAJECTORY
#p0 is initial, p2 is final and p1 determines curve, t range is from 0 to 1
func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	return r
func set_arc_indicator():
	var throw_distance = clamp(get_local_mouse_position().x, -max_throw_radius, max_throw_radius)
	for i in bezier_resolution:
		arc_indicator.set_point_position(i + 1, quadratic_bezier(Vector2.ZERO, Vector2(0.5*throw_distance, -abs(throw_distance)), Vector2(throw_distance,0), 1.0 / float(bezier_resolution) * (i + 1)))
#endregion

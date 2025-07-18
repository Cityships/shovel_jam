extends Gadget

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var arc_indicator : Line2D = get_node("ArcIndicator")
@onready var scene = get_parent()
@onready var interactable_area : Area2D = get_node("InteractableArea")
@onready var windup_progress_bar : ProgressBar = get_node("ProgressBar")
@onready var audio_stream_player : AudioStreamPlayer2D = get_node("AudioStreamPlayer2D")



@export var max_throw_force_multiplier : float = 500
@export var audio_playlist : AudioStreamPlaylist
@export var max_throw_radius : float = 128
@export var bezier_resolution : int = 16
@export var emp_explosion_effect : PackedScene




var emp_instance
var tween
var player
var hold_emp : bool
var armed_emp : bool
var gadget_in_use : bool

func _ready() -> void:

	GlobalEvents.player_death.connect(
		func():
			if Globals.obtained_gadgets.has(self):
				GlobalEvents.request_pickup_gadget.emit(self)
	)

	emp_instance = emp_explosion_effect.instantiate()
	add_child(emp_instance)
	interactable_area.body_entered.connect(func(value): player = value)
	interactable_area.body_exited.connect(func(_value): player = null)

	auto_trigger.connect(
		func():
			await get_tree().create_timer(0.5).timeout
			if windup_progress_bar.value == windup_progress_bar.max_value:
				emp_instance.play_animation()
				windup_progress_bar.value = 0
				windup_progress_bar.modulate = Color.WHITE
				audio_stream_player.stream = audio_playlist.get_list_stream(3)
				audio_stream_player.play()
	)

func recharge(value):
	windup_progress_bar.value += value
	if windup_progress_bar.value == windup_progress_bar.max_value:
		windup_progress_bar.modulate = Color.GREEN
	else:
		windup_progress_bar.modulate = Color.WHITE

func force_recharge(value):
	recharge(value)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept") and player != null:
		if !armed_emp:
			audio_stream_player.stream = audio_playlist.get_list_stream(0)
			audio_stream_player.play()
		freeze = true
		reparent(player)
		self.position = Vector2(0,-32)
		hold_emp = true
		gadget_in_use = true


	if Input.is_action_just_released("ui_accept") and hold_emp:
		freeze = false
		reparent(scene, true)
		
		if !armed_emp:	
			audio_stream_player.stream = audio_playlist.get_list_stream(1)
			audio_stream_player.play()
		
		var throw_force = Vector2.ZERO
		throw_force.x = clamp(get_local_mouse_position().x, -max_throw_force_multiplier, max_throw_force_multiplier)
		throw_force.y = clamp(get_local_mouse_position().y, -max_throw_force_multiplier, max_throw_force_multiplier)

		self.apply_impulse((get_global_mouse_position() - global_position).normalized() * throw_force.length())
		hold_emp = false

		if !armed_emp and windup_progress_bar.value == windup_progress_bar.max_value:
			armed_emp = true
			tween = create_tween()
			sprite.play("WindUp")
			var ticks = 4
			tween.tween_interval(1)
			tween.chain().tween_callback(func():audio_stream_player.stream = audio_playlist.get_list_stream(2))
			for i in ticks:
				tween.chain().tween_interval(2.0/(ticks + 0.01))
				tween.chain().tween_callback(audio_stream_player.play)
			for i in ticks:
				tween.chain().tween_interval(1.0/(ticks + 0.5*i))
				tween.chain().tween_callback(audio_stream_player.play)
			tween.chain().tween_callback(func():emp_instance.play_animation())
			tween.chain().tween_callback(
				func():
					windup_progress_bar.value = 0
					windup_progress_bar.modulate = Color.WHITE
					audio_stream_player.stream = audio_playlist.get_list_stream(3)
					audio_stream_player.play()
					sprite.play("Detonated")
					audio_stream_player.finished.connect(func():audio_stream_player.stream = null)
					armed_emp = false
					gadget_in_use = false
					await get_tree().create_timer(1.0).timeout
					sprite.play("Idle")
			)
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

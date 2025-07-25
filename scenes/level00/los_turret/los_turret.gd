extends StaticBody2D

signal emp_disabled

enum State {CHARGE, SHOOT, RELOAD}

@onready var laser_line : Line2D = %LaserLine
var tracer : Line2D
@onready var detection_ray : RayCast2D = %LaserRaycast
@onready var danger_area : Area2D = get_node("DangerArea")
@onready var turret_gun_remote_transform : RemoteTransform2D = get_node("RemoteTransform2D")
@export var charge_duration : float = 2
@export var fire_duration : float = 2
@onready var cooldown_timer : Timer = get_node("CooldownTimer")
@onready var cycle_timer : Timer = get_node("CycleTimer")

@onready var audio_player : AudioStreamPlayer2D = get_node("AudioStreamPlayer2D")
@export var audio_playlist : AudioStreamPlaylist

var player_target = null
var last_target_position : Vector2
var disabled : bool = false

var laser_firing : bool
var player_on_danger_area : bool

@export_enum("face_left", "face_right") var flip_h = 1

func _ready() -> void:
	tracer = detection_ray.get_node("Tracer")
	var refs = get_tree().get_nodes_in_group("Player")
	player_target = refs[0]
	danger_area.body_exited.connect(func(value): if value == player_target: player_on_danger_area = false)
	danger_area.body_entered.connect(func(value): if value == player_target: player_on_danger_area = true)
	cycle_timer.timeout.connect(check_los)
	emp_disabled.connect(
		func(value):
			disabled = true
			var tween = create_tween()
			tween.tween_interval(value)
			tween.chain().tween_callback(func():disabled = false),
		)

func _process(delta: float) -> void:
	if !player_on_danger_area:
		return
	if player_target != null:
		turret_gun_remote_transform.look_at(player_target.global_position + Vector2(0, -8))
	if laser_firing:
		laser_line.set_point_position(1, detection_ray.to_local(detection_ray.get_collision_point()))
		if detection_ray.get_collider() == player_target:
			GlobalEvents.player_death.emit()
			detection_ray.collide_with_bodies = false
	tracer.set_point_position(1, detection_ray.to_local(detection_ray.get_collision_point()))

func check_los():
	if disabled:
		return
	detection_ray.collide_with_bodies = true
	if !cooldown_timer.is_stopped():
		return
	if player_target == null and last_target_position != Vector2.ZERO and !cooldown_timer.is_stopped():
		if (detection_ray.get_collision_point() - last_target_position).length() < 32:
			play_attack_sequence()
	if player_target != null:
		if (detection_ray.get_collision_point() - player_target.global_position).length() < 32:
			play_attack_sequence()


func play_attack_sequence():
	cooldown_timer.start()
	laser_line.points = [Vector2.ZERO, Vector2.ZERO]
	var tween = create_tween()
	tween.tween_callback(
		func():
			audio_player.volume_db = 0.0
			audio_player.stream = audio_playlist.get_list_stream(0)
			audio_player.play()
	)
	tween.chain().tween_method(
		func(value):
			audio_player.pitch_scale = value,
		0.5, 1.0, charge_duration
	)
	tween.chain().tween_callback(func():
		audio_player.stream = audio_playlist.get_list_stream(1)
		audio_player.play()
	)
	tween.chain().tween_callback(func():laser_firing = true)
	tween.chain().tween_interval(fire_duration)
	tween.chain().tween_callback(func():laser_firing = false; laser_line.clear_points())
	tween.chain().tween_method(
		func(value):
			audio_player.volume_db = value,
		0.0, -22, 0.5
	)
	tween.chain().tween_callback(func():audio_player.stop())

	

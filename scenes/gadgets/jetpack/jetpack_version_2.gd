extends RigidBody2D

@onready var interactable_area : Area2D = get_node("InteractableArea")
@onready var player_area : CollisionShape2D = get_node("PlayerArea")
@onready var raycast : RayCast2D = get_node("RayCast2D")
@onready var windup_progress_bar : ProgressBar = get_node("ProgressBar")
@onready var remote_transform : RemoteTransform2D = get_node("RemoteTransform2D")
@export var discharge_rate : float = 20.0
@export var starting_charge = 100.0
@export var max_force_recharge_count : int = 1
var forced_recharge_count : int = 0

@export_group("Audio")
@export var audio_playlist : AudioStreamPlaylist
@onready var audio_player : AudioStreamPlayer2D = get_node("AudioStreamPlayer2D")
@onready var equip_audio_stream : AudioStreamPlayer2D = get_node("EquipAudioStream") 
@export var startup_delay : float = 2.5
var startup_timer : Timer
var input_hold_timer : Timer
var out_of_power : bool = false

var input_direction : Vector2

var player : Node2D
var gadget_in_use : bool:
	set(value):
		gadget_in_use = value
		if gadget_in_use:
			player.movement_restriction_count = 1
			var temp = to_local(player.global_position)
			remote_transform.position = round(temp.normalized()) * 32
			if abs(remote_transform.position.y) == abs(remote_transform.position.x):
				remote_transform.position.y = 0
			if remote_transform.position.x > 0:
				windup_progress_bar.position = Vector2(-32,-16)
			else:
				windup_progress_bar.position = Vector2(24,-16)
			player_area.position = remote_transform.position
			player_area.set_deferred("disabled", false)
			remote_transform.update_position = true
		else:
			player.movement_restriction_count = 0
			remote_transform.update_position = false
			player_area.set_deferred("disabled", true)
			remote_transform.update_position = false
		

var can_attach_player : bool

func _ready() -> void:

	GlobalEvents.request_pickup_gadget.connect(
		func(_value):
			gadget_in_use = false
			audio_player.stop()
			input_hold_timer.stop()
	)

	player = get_tree().get_nodes_in_group("Player")[0]
	remote_transform.remote_path = player.get_path()
	interactable_area.body_entered.connect(func(_value):can_attach_player = true)
	interactable_area.body_exited.connect(func(_value):can_attach_player = false)

	startup_timer = Timer.new()
	startup_timer.wait_time = startup_delay
	startup_timer.autostart = false
	startup_timer.one_shot = true
	add_child(startup_timer)

	input_hold_timer = Timer.new()
	input_hold_timer.wait_time = 2000
	input_hold_timer.autostart = false
	input_hold_timer.one_shot = true
	add_child(input_hold_timer)

	audio_player.finished.connect(
		func():
			if !input_hold_timer.is_stopped() and !out_of_power:
				audio_player.stream = audio_playlist.get_list_stream(2)
				audio_player.play()
	)

func recharge(value):
	if raycast.is_colliding():
		windup_progress_bar.value += value
		if windup_progress_bar.value == windup_progress_bar.max_value:
			windup_progress_bar.modulate = Color.GREEN
		else:
			windup_progress_bar.modulate = Color.WHITE
	if windup_progress_bar.value > 0:
		out_of_power = false

func force_recharge(value):
	if forced_recharge_count < max_force_recharge_count:	
		forced_recharge_count += 1
		windup_progress_bar.value += value
		if windup_progress_bar.value == windup_progress_bar.max_value:
			windup_progress_bar.modulate = Color.GREEN
		else:
			windup_progress_bar.modulate = Color.WHITE
		if windup_progress_bar.value > 0:
			out_of_power = false

func _process(delta: float) -> void:
	if input_direction != Vector2.ZERO and gadget_in_use:
		windup_progress_bar.value -= discharge_rate * delta
		windup_progress_bar.modulate = Color.WHITE
	if windup_progress_bar.value == 0 and audio_player.playing and !out_of_power:
		out_of_power = true
		audio_player.stream = audio_playlist.get_list_stream(3)
		audio_player.play()
	if raycast.is_colliding():
		forced_recharge_count = 0

func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("ui_accept") and can_attach_player:
		gadget_in_use = true

	if Input.is_action_just_released("ui_accept") and gadget_in_use:
		if audio_player.playing:
			audio_player.stream = audio_playlist.get_list_stream(3)
			audio_player.play()
		input_hold_timer.stop()
		startup_timer.stop()
		gadget_in_use = false
		

	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_up", "ui_down")
	if gadget_in_use and windup_progress_bar.value > 0:
		
		constant_force = input_direction * Vector2(0.25, 1.25)

		if constant_force != Vector2.ZERO and startup_timer.is_stopped() and input_hold_timer.is_stopped():
			startup_timer.start()
			input_hold_timer.start()
			audio_player.stream = audio_playlist.get_list_stream(1)
			audio_player.play()
			audio_player.volume_db = -20
			var tween = create_tween()
			tween.tween_property(audio_player, "volume_db", 0, 0.3)

		audio_player.pitch_scale = 1+(constant_force.length_squared()-0.6)*0.25

	else:
		constant_force = Vector2.ZERO

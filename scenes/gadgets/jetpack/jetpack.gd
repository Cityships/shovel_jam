extends Gadget
class_name JetPack

@onready var interactable_area : Area2D = get_node("InteractableArea")
@onready var windup_progress_bar : ProgressBar = get_node("ProgressBar")
@onready var raycast : RayCast2D = get_node("RayCast2D")
@export var discharge_rate : float = 20.0
@onready var debug: Label = %Debug

@export_group("Audio")
@export var audio_playlist : AudioStreamPlaylist
@onready var audio_player : AudioStreamPlayer2D = get_node("AudioStreamPlayer2D")
@onready var equip_audio_stream : AudioStreamPlayer2D = get_node("EquipAudioStream") 
@export var startup_delay : float = 2.5
var startup_timer : Timer
var input_hold_timer : Timer
var out_of_power : bool = false

var input_direction : Vector2

var player
var hold_player : bool
@onready var player_area : CollisionShape2D = get_node("PlayerArea")

var gadget_in_use : bool

func _ready() -> void:
	interactable_area.body_entered.connect(func(value): player = value)
	interactable_area.body_exited.connect(
		func(value):
			if !hold_player:
				value.movement_restriction_count = 0
				player = null
				hold_player = false
				player_area.set_deferred("disabled", true)
	)

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
	if windup_progress_bar.value > 0:
		out_of_power = false

func _process(delta: float) -> void:
	if input_direction != Vector2.ZERO and hold_player:
		windup_progress_bar.value -= discharge_rate * delta
	if windup_progress_bar.value == 0 and audio_player.playing and !out_of_power:
		out_of_power = true
		audio_player.stream = audio_playlist.get_list_stream(3)
		audio_player.play()


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("ui_accept") and player != null:
		gadget_in_use = true
		equip_audio_stream.stream = audio_playlist.get_list_stream(0)
		equip_audio_stream.play()

	if Input.is_action_pressed("ui_accept") and player != null:

		player.movement_restriction_count = 1
		hold_player = true
		player.reparent(self, true)
		player.position = round(player.position.normalized()) * 32
		if abs(player.position.y) == abs(player.position.x):
			player.position.y = 0
		if player.position.x > 0:
			windup_progress_bar.position = Vector2(-32,-16)
		else:
			windup_progress_bar.position = Vector2(24,-16)

		player_area.position = player.position
		player_area.set_deferred("disabled", false)

	if Input.is_action_just_released("ui_accept") and hold_player:

		if audio_player.playing:
			audio_player.stream = audio_playlist.get_list_stream(3)
			audio_player.play()
		input_hold_timer.stop()
		startup_timer.stop()

		player.movement_restriction_count = 0
		hold_player = false
		player.reparent(get_parent())
		player_area.set_deferred("disabled", true)
		gadget_in_use = false
		

	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_up", "ui_down")
	if hold_player and windup_progress_bar.value > 0:
		
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
	
	

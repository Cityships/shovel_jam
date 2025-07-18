extends Gadget
class_name JetPack



@onready var jetpack_sprite: Sprite2D = %JetpackSprite
@onready var key_left: AnimatedSprite2D = %KeyLeft
@onready var key_right: AnimatedSprite2D = %KeyRight
@onready var interactable_area : Area2D = get_node("InteractableArea")
@onready var windup_progress_bar : ProgressBar = get_node("ProgressBar")
@onready var raycast : RayCast2D = get_node("RayCast2D")
@onready var debug: Label = %Debug
@onready var player_area : CollisionShape2D = get_node("PlayerArea")
@onready var stream: AnimatedSprite2D = %Stream

@export var max_force_recharge_count : int = 1
@export var discharge_rate : float = 20.0
@export var starting_charge = 100.0
@export_group("Audio")
@export var audio_playlist : AudioStreamPlaylist
@onready var audio_player : AudioStreamPlayer2D = get_node("AudioStreamPlayer2D")
@onready var equip_audio_stream : AudioStreamPlayer2D = get_node("EquipAudioStream") 
@export var startup_delay : float = 2.5


var startup_timer : Timer
var input_hold_timer : Timer
var out_of_power : bool = false
var forced_recharge_count : int = 0
var input_direction : Vector2
var player
var hold_player : bool
var death_override : bool
var gadget_in_use : bool

func _ready() -> void:

	GlobalEvents.player_death.connect(
		func():
			get_tree().create_timer(1).timeout.connect(func():death_override = false)
			death_override = true
			audio_player.stop()
			hold_player = false
			gadget_in_use = false
			player = null
			GlobalEvents.request_pickup_gadget.emit(self)
	)
	
	windup_progress_bar.value = starting_charge
	interactable_area.body_entered.connect(func(value): player = value)
	interactable_area.body_exited.connect(
		func(value):
			if hold_player and (global_position - player.global_position).length() > 32:
				value.movement_restriction_count = 0
				if player.get_parent() == self:
					await get_tree().create_timer(0.5).timeout
				player.reparent(get_parent())
				player = null
				hold_player = false
				audio_player.stop()
				player_area.set_deferred("disabled", true)
			if !hold_player or death_override:
				value.movement_restriction_count = 0
				player = null
				hold_player = false
				audio_player.stop()
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
		if windup_progress_bar.value == windup_progress_bar.max_value:
			windup_progress_bar.modulate = Color.GREEN
			key_right.set_visible(false)
		else:
			windup_progress_bar.modulate = Color.WHITE
			key_right.set_visible(true)
			
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
	if input_direction != Vector2.ZERO and hold_player:
		windup_progress_bar.value -= discharge_rate * delta
		windup_progress_bar.modulate = Color.WHITE
		stream.set_visible(true)
	if windup_progress_bar.value == 0 and audio_player.playing and !out_of_power:
		out_of_power = true
		audio_player.stream = audio_playlist.get_list_stream(3)
		audio_player.play()
	if raycast.is_colliding():
		forced_recharge_count = 0

func _input(event: InputEvent) -> void:

	if death_override:
		return

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
		stream.set_visible(false)
		

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
	
	

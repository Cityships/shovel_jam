extends Node

signal request_pickup_gadget
signal request_deploy_gadget
signal create_quick_tip

signal progress_story_bot
signal story_bot_index_changed
signal story_bot_skip_to_index

signal player_death
signal set_checkpoint

signal key_obtained
signal gadget_obtained

signal control_option_switch
var control_option : int = -1

func _ready() -> void:
	control_option_switch.emit(control_option)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("switch_control_options"):
		control_option = - control_option
		control_option_switch.emit(control_option)

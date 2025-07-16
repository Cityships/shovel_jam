extends Node2D

var msg_timeout : Timer

func _ready() -> void:
	msg_timeout = Timer.new()
	msg_timeout.autostart = false
	msg_timeout.one_shot = true
	add_child(msg_timeout)
	GlobalEvents.request_pickup_gadget.connect(on_player_pickup_gadget)
	GlobalEvents.request_deploy_gadget.connect(deploy_gadget)

func on_player_pickup_gadget(gadget : RigidBody2D):
	if !gadget.gadget_in_use:
		await get_tree().create_timer(0.25).timeout
		gadget.reparent(self)
		gadget.position = Vector2.ZERO
		gadget.visible = false
		gadget.freeze = true

func deploy_gadget(deploy_location : Vector2, gadget_name):
	var gadget : RigidBody2D = get_node_or_null(gadget_name)
	if gadget != null:
		msg_timeout.start(2)
		gadget.visible = true
		gadget.global_position = deploy_location
		gadget.reparent(get_parent())
		gadget.freeze = false
	elif msg_timeout.is_stopped():
		GlobalEvents.create_quick_tip.emit(deploy_location, str("Gadget_manager: ", gadget_name," gadget not found."))
		msg_timeout.start(4)

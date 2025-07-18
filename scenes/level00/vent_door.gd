extends Sprite2D

@onready var area_2d : Area2D = get_node("Area2D")
@onready var teleport_point = get_node("TeleportPoint")
var jet_pack : Node2D

func _ready() -> void:
	area_2d.body_entered.connect(teleport_player)

func teleport_player(player):
	for gadget in Globals.obtained_gadgets:
		GlobalEvents.request_pickup_gadget.emit(gadget)
	player.global_position = teleport_point.global_position

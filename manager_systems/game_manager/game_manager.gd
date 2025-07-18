extends Node2D

var checkpoint
var player
var scene

func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player")[0]
	scene = player.get_parent()
	GlobalEvents.player_death.connect(respawn_player)
	GlobalEvents.set_checkpoint.connect(func(value): checkpoint = value)

func respawn_player():
	var tween = create_tween()
	for gadget in Globals.obtained_gadgets:
		tween.chain().tween_callback(func(): GlobalEvents.request_pickup_gadget.emit(gadget))
	tween.chain().tween_property(player, "global_position", checkpoint.global_position, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

extends Node2D

var checkpoint
var player
var scene

func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player")[0]
	scene = player.get_parent()
	GlobalEvents.player_death.connect(respawn_player)
	GlobalEvents.set_checkpoint.connect(func(value): checkpoint = value)

func respawn_player() -> void:
	var target = Globals.checkpoint
	if target == Vector2.ZERO:
		target = Globals.start_point

	var tween := create_tween()
	tween.tween_callback(func(): player.reparent(scene))
	tween.tween_property(
		player, "global_position",
		target, 0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

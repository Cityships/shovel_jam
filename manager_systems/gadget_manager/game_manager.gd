extends Node2D

var checkpoint

func _ready() -> void:
	GlobalEvents.player_death.connect(respawn_player)
	GlobalEvents.set_checkpoint.connect(func(value): checkpoint = value)

func respawn_player(player):
	var tween = create_tween()
	#play the death sequence
	tween.tween_property(player, "global_position", checkpoint.global_position, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

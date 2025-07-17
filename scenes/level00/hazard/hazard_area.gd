extends Area2D

func _ready() -> void:
	body_entered.connect(func(_player): GlobalEvents.player_death.emit()) 

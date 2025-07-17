extends Area2D

func _ready() -> void:
    body_entered.connect(func(player): GlobalEvents.player_death.emit(player)) 
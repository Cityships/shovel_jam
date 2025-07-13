extends Camera2D

@export var player : Node2D
@export var follow_player_speed : float = 5.0

func _physics_process(delta: float) -> void:
	self.position = self.position.lerp(player.position + Vector2(0, -16), delta * follow_player_speed)

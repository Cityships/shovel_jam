class_name Patroller extends BaseEnemyManager



func _ready():
	base_enemy_body.enter_state(BaseEnemyBody.State.MOVE) 

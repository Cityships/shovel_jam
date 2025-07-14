class_name BaseEnemyManager extends Node2D
## Thinking of using this as the Main Observer for the Enemy Mobs.
## All Signals from Enemy Body/Children will be receveid here. 
@onready var base_enemy_body: BaseEnemyBody = %BaseEnemyBody
@onready var sprite: Sprite2D = %Sprite
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D

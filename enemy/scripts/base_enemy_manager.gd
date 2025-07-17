class_name BaseEnemyManager extends Node2D
## Thinking of using this as the Main Observer for the Enemy Mobs.
## All Signals from Enemy Body/Children will be receveid here. 


const BASE_ENEMY_BODY = preload("res://scenes/enemy/base_enemy_body.tscn")
const COLLISION_SHAPE_2D = preload("res://scenes/enemy/collision_shape_2d.tscn")
const VISUAL_TREE_ROOT = preload("res://scenes/enemy/visual_tree_root.tscn")

var base_enemy_body: BaseEnemyBody 
var sprite: Sprite2D
var collision_shape_2d: CollisionShape2D


@export var enemy_resource: EnemyResource

func _ready() -> void:
	var body = BASE_ENEMY_BODY.instantiate()
	var shape = COLLISION_SHAPE_2D.instantiate()
	var visual = VISUAL_TREE_ROOT.instantiate()
	
	add_child(body)
	base_enemy_body = body
	add_child(shape)
	collision_shape_2d = shape
	add_child(visual)
	sprite = visual

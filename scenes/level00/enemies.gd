class_name Enemies extends Node2D
const MEN_IN_BLACK = preload("res://scenes/enemy/men_in_black/men_in_black.tscn")

@onready var _1: Node2D = %"1"
@onready var _2: Node2D = %"2"
@onready var _3: Node2D = %"3"
@onready var _4: Node2D = %"4"

var men_in_black 
func _ready() -> void:
	GlobalEvents.light_key_event.connect(_on_light_key_event)
	
	

func _on_light_key_event() -> void:
	var mib1 = MEN_IN_BLACK.instantiate()
	var mib2 = MEN_IN_BLACK.instantiate()
	var mib3 = MEN_IN_BLACK.instantiate()
	var mib4 = MEN_IN_BLACK.instantiate()
	await get_tree().process_frame
	_1.add_child(mib1)
	_2.add_child(mib2)
	_3.add_child(mib3)
	_4.add_child(mib4)

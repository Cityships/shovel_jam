extends Node2D

@export var quick_tip_scene : PackedScene

func _ready() -> void:
	GlobalEvents.create_quick_tip.connect(instance_quick_tip)

func instance_quick_tip(location : Vector2, text : String, extra_duration : float = 1.0, text_color : Color = Color.WHITE):
	var instance : Label = quick_tip_scene.instantiate()
	instance.text = text
	instance.modulate = text_color
	instance.global_position = location

	get_parent().add_child(instance)
	
	var tween = create_tween()
	tween.tween_property(instance, "global_position", instance.global_position + Vector2(0, -64), 2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(extra_duration)
	tween.finished.connect(instance.queue_free)

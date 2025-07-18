extends VBoxContainer

@onready var text_lines : Control = %TextLines
@onready var text_index : int = 0:
	set(value):
		if text_index == value:
			return
		text_index = value
		GlobalEvents.story_bot_index_changed.emit(value)

@export var stop_indices : PackedInt32Array

func _ready() -> void:
	for child in text_lines.get_children():
		child.visible = false
	text_lines.get_child(0).visible = true
	GlobalEvents.progress_story_bot.connect(show_next_text)
	GlobalEvents.story_bot_skip_to_index.connect(skip_to_text)


func show_next_text():
	text_lines.get_child(text_index).visible = false
	text_index += 1
	text_lines.get_child(text_index).visible = true

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("acknowledge_text") and !stop_indices.has(text_index):
		GlobalEvents.progress_story_bot.emit()

func skip_to_text(index):
	text_lines.get_child(text_index).visible = false
	text_index = index
	text_lines.get_child(text_index).visible = true

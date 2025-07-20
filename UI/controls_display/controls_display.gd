extends Control

@onready var tabs : TabContainer = %TabContainer
@onready var instruction_text : RichTextLabel = %InstructionText
var key_options
var gadget_options

func _ready() -> void:
	
	gadget_options = tabs.get_child(0)
	key_options = tabs.get_child(1)

	GlobalEvents.story_bot_index_changed.connect(
		func(value):
			if value == 4:
				instruction_text.text = str(instruction_text.text, "Press Q to switch to keys. Click on the key gizmo and spin it. Use keys to charge nearby objects. ")
			if value == 7:
				instruction_text.text = str(instruction_text.text, "Press and hold space to interact with gadgets. Use WASD to maneuver the jetpack.")
			if value == 8:
				gadget_options.get_node("Label").visible = true
				gadget_options.get_node("Label3").visible = true
	)
	GlobalEvents.gadget_obtained.connect(
		func(value):
			if value.name == "EmpObject":
				gadget_options.get_node("Label2").visible = true
			instruction_text.text = ""
			instruction_text.text = str(instruction_text.text, "Press Q to switch to gadgets and 2 to deploy the emp. Charge and throw the emp object.")

	)
	GlobalEvents.key_obtained.connect(
		func():
			if Globals.obtained_keys.has(2):
				key_options.get_node("Label2").visible = true
			instruction_text.text = ""
			instruction_text.text = str(instruction_text.text, "Press Q and 2 to switch the light key. Charge nearby objects with the light key. After spinning the light key will remotely trigger objects")
	)

	GlobalEvents.control_option_switch.connect(func(value): tabs.current_tab = max(0, value))

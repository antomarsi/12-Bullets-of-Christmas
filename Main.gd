extends Control

@onready var _start: Button = $Buttons/Start
@onready var _continue: Button = $Buttons/Continue
@onready var _night_select: Button = $Buttons/NightSelect
@onready var _quit: Button = $Buttons/Quit

func _ready() -> void:
	_start.pressed.connect(func(): get_tree().change_scene_to_file("res://interface/Intro.tscn"))
	_continue.visible = SaveData.has_progress()
	_continue.pressed.connect(func(): Game.start_night(SaveData.continue_night()))
	# Debug builds always show it, so every built night can be tested.
	_night_select.visible = SaveData.has_progress() or OS.is_debug_build()
	_night_select.pressed.connect(func(): get_tree().change_scene_to_file("res://interface/NightSelect.tscn"))
	_quit.pressed.connect(get_tree().quit)
	_start.grab_focus()

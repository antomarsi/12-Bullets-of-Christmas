extends Control

@onready var _button_start = $Buttons/Start
@onready var _button_exit = $Buttons/Exit

func _ready() -> void:
	_button_exit.connect("pressed", Callable(get_tree(), "quit"))
	_button_start.connect("pressed", Callable(get_tree(), "change_scene_to_file").bind("res://interface/Intro.tscn"))

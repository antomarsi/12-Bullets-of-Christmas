extends Control

onready var _button_start = $Buttons/Start
onready var _button_exit = $Buttons/Exit

func _ready() -> void:
	_button_exit.connect("pressed", get_tree(), "quit")
	_button_start.connect("pressed", get_tree(), "change_scene", ["res://interface/Intro.tscn"])

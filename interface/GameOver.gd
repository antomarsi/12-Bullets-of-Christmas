extends Control


@onready var _button_retry := $CenterContainer/VBoxContainer/Retry
@onready var _button_menu := $CenterContainer/VBoxContainer/Menu


func _ready() -> void:
	_button_retry.connect("pressed", Callable(self, "_on_restartButton_pressed"))
	_button_menu.connect("pressed", Callable(self, "_on_MenuButton_pressed"))
	
	_button_retry.grab_focus()

func _on_restartButton_pressed() -> void:
	get_tree().change_scene_to_file(Events.last_room)

func _on_MenuButton_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")

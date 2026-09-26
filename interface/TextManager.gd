extends Control

# Empty = start night 1 (verse screen, then the room).
@export_file("*.tscn") var next_world: String = ""
@export var speed := 30.0

@onready var label_container = $CenterContainer2/VBoxContainer

func _ready():
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR)
	for label in label_container.get_children():
		label.visible_ratio = 0.0
		var duration : float = label.text.length() / speed
		tween.tween_property(label, "visible_ratio", 1.0, duration)
	tween.tween_interval(1.5)
	tween.finished.connect(_finish)

func _finish() -> void:
	if next_world == "":
		Game.start_night(1)
	else:
		get_tree().change_scene_to_file(next_world)

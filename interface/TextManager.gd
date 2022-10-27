extends Control

export (PackedScene) var next_world
export var speed = 30

onready var label_container = $CenterContainer2/VBoxContainer
onready var timer = $Timer

func _ready():
	for label in label_container.get_children():
		label.percent_visible = 0.0
	
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR)
	for label in label_container.get_children():
		label.percent_visible = 0.0
		var duration : float = label.text.length() / speed
		tween.tween_property(label, "percent_visible", 1.0, duration)

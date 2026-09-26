extends Control

# Empty = start night 1 (transition scene, then the room).
@export_file("*.tscn") var next_world: String = ""
@export var speed := 30.0

@onready var label_container = $CenterContainer2/VBoxContainer

var _done := false

func _ready():
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR)
	for label in label_container.get_children():
		label.visible_ratio = 0.0
		var duration : float = label.text.length() / speed
		tween.tween_property(label, "visible_ratio", 1.0, duration)
	tween.tween_interval(1.5)
	tween.finished.connect(_finish)
	_add_skip_hint()

func _add_skip_hint() -> void:
	var hint := Label.new()
	hint.text = "ESC: SKIP"
	hint.add_theme_font_override("font", load("res://fonts/pixelart.ttf"))
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	add_child(hint)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	if next_world == "":
		Game.start_night(1)
	else:
		get_tree().change_scene_to_file(next_world)

class_name WaveBanner
extends CanvasLayer

var _label := Label.new()

func _init() -> void:
	layer = 20
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.position.y = 60
	_label.add_theme_font_override("font", load("res://fonts/pixelart.ttf"))
	_label.add_theme_font_size_override("font_size", 40)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.modulate.a = 0.0
	add_child(_label)

func show_text(text: String, hold := 1.4) -> void:
	_label.text = text
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	var tween := create_tween()
	tween.tween_property(_label, "modulate:a", 1.0, 0.25)
	tween.tween_interval(hold)
	tween.tween_property(_label, "modulate:a", 0.0, 0.4)

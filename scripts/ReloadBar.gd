class_name ReloadBar
extends Node2D

# A small bar above the player that fills while reloading.
@export var bar_width := 26
@export var bar_height := 4
@export var fill_color := Color(1.0, 0.85, 0.3)

var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var active := false

func _ready() -> void:
	z_index = 100
	visible = false

func begin() -> void:
	active = true
	progress = 0.0
	visible = true

func finish() -> void:
	active = false
	visible = false

func _draw() -> void:
	if not active:
		return
	var x := -bar_width / 2
	draw_rect(Rect2(x - 1, -1, bar_width + 2, bar_height + 2), Color(0, 0, 0, 0.9))
	draw_rect(Rect2(x, 0, bar_width, bar_height), Color(0.25, 0.25, 0.3))
	draw_rect(Rect2(x, 0, int(bar_width * progress), bar_height), fill_color)

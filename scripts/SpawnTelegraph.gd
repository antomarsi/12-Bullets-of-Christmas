class_name SpawnTelegraph
extends Node2D

var duration := 0.7
var on_done := Callable()
var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= duration:
		if on_done.is_valid():
			on_done.call()
		queue_free()

func _draw() -> void:
	var k := clampf(_t / duration, 0.0, 1.0)
	draw_arc(Vector2.ZERO, 8.0 + 26.0 * (1.0 - k), 0.0, TAU, 24, Color(1.0, 0.3, 0.3, 0.9), 2.0)
	draw_circle(Vector2.ZERO, 8.0 * k, Color(1.0, 0.3, 0.3, 0.5))

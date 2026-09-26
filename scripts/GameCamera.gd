class_name GameCamera
extends Camera2D

# Follows the target at a fixed 2x zoom (the world shows 640x360 of the 1280x720 base
# resolution). The position is rounded to whole world pixels so pixel art stays crisp.
@export var target: Node2D
@export var smoothing := 10.0
@export_range(0.0, 0.5) var look_ahead := 0.1

var _shake := 0.0

func _ready() -> void:
	zoom = Vector2(2, 2)
	position_smoothing_enabled = false
	add_to_group("camera")
	make_current()
	if target:
		global_position = target.global_position.round()

func set_limits(rect: Rect2) -> void:
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.end.x)
	limit_bottom = int(rect.end.y)

func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var goal := target.global_position
	goal += (get_global_mouse_position() - goal) * look_ahead
	var t := 1.0 - exp(-smoothing * delta)
	global_position = global_position.lerp(goal, t).round()
	if _shake > 0.05:
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).round() * _shake
		_shake = move_toward(_shake, 0.0, 30.0 * delta)
	else:
		offset = Vector2.ZERO
		_shake = 0.0

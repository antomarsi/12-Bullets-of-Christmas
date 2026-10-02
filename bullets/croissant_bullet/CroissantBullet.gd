extends BulletBase

# Curves through a full loop and comes back toward where it was thrown from, like a boomerang,
# instead of flying in a straight line. Spinning the node's own rotation to steer also makes the
# sprite visibly tumble as it flies, which reads well for a thrown pastry.
@export var loop_time := 2.2
@export var curve_direction := 1.0

var _angular_speed := 0.0

func _on_spawn() -> void:
	super._on_spawn()
	_angular_speed = TAU / loop_time * curve_direction
	max_range = speed * loop_time

func _move(delta: float) -> void:
	rotation += _angular_speed * delta
	position += transform.x * speed * delta
	_travelled_distance += speed * delta
	if _travelled_distance > max_range:
		_destroy()

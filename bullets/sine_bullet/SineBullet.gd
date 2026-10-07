extends BulletBase

@export var wave_amplitude := 40.0
# Radians of sine phase advanced per pixel travelled — smaller reads as a lazier, wider wiggle.
@export var wave_frequency := 0.025

var _base_position := Vector2.ZERO
var _forward := Vector2.RIGHT

func _on_spawn() -> void:
	super._on_spawn()
	# position/rotation are already set by BulletPattern.shoot() before this runs (both for a
	# fresh instance and a pooled reuse), so this captures the real spawn pose each time.
	_base_position = position
	_forward = transform.x

func _move(delta: float) -> void:
	var step := speed * delta
	_travelled_distance += step
	_base_position += _forward * step
	var lateral := _forward.orthogonal() * sin(_travelled_distance * wave_frequency) * wave_amplitude
	position = _base_position + lateral
	if _travelled_distance > max_range:
		_destroy()

extends Node2D
class_name AimComponent

@onready var weapon_pivot := $AimPivot
@onready var point := $AimPivot/ShootingPoint

func move_aim(position: Vector2):
	weapon_pivot.look_at(position)

func get_shoot_position() -> Transform2D:
	return point.global_transform

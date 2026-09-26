extends Node2D
class_name VelocityComponent

@export var MAX_SPEED := 100.0
@export var acceleration := 1000.0;
var friction: float : get = get_friction

var direction : Vector2
var velocity : Vector2
var is_running : bool : get = get_is_running

func get_friction():
	return (acceleration / MAX_SPEED)

func move(characterBody: CharacterBody2D):
	accelerate_in_direction(direction)
	characterBody.velocity = velocity
	characterBody.move_and_slide()

func accelerate_to_velocity(acceleration : Vector2):
	velocity = velocity.lerp(acceleration, 0.1)

func accelerate_in_direction(direction: Vector2):
	accelerate_to_velocity(direction * MAX_SPEED)

func get_is_running():
	return velocity.length() > MAX_SPEED / 2.0

func decelerate():
	accelerate_to_velocity(Vector2.ZERO)

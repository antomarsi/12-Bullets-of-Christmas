extends KinematicBody2D

signal shoot
signal died

export (PackedScene) var Bullet
var can_shoot = false

export (int) var MAX_SPEED = 300
export (float) var MAX_FORCE = 0.02
export (Vector2) var DISTANCE = Vector2()
export (float) var SHOOT_TIMER = 2
export (int) var HEALTH = 10

var velocity = Vector2()
onready var target = get_node("/root/Root/Player")

func _ready():
	$GunTimer.wait_time = SHOOT_TIMER
	$GunTimer.start()
	pass
	
func _physics_process(delta):
	if HEALTH <= 0:
		pass
	velocity = steer(target.global_position)
	move_and_slide(velocity)
	
func _process(delta):
	if HEALTH <= 0:
		pass
	_shoot(delta)

func steer(target):
	var desired_velocity = (target - position)
	desired_velocity = desired_velocity.normalized() * MAX_SPEED
	var steer = desired_velocity - velocity
	var target_velocity = velocity + (steer * MAX_FORCE)
	return target_velocity

func steer_keep_distance(target):
	var desired_velocity = (target - position) + DISTANCE
	desired_velocity = desired_velocity.normalized() * MAX_SPEED
	var steer = desired_velocity - velocity
	var target_velocity = velocity + (steer * MAX_FORCE)
	return target_velocity

func flee(target):
	var desired_velocity = (target - position).normalized() * MAX_SPEED
	var steer = (-1 * desired_velocity) - velocity
	var target_velocity = velocity + (steer * MAX_FORCE)
	return target_velocity
	
func _shoot(delta):
	if can_shoot and Bullet:
		can_shoot = false
		$GunTimer.start()
		var dir = (target.global_position - global_transform.origin).normalized()
		emit_signal('shoot', Bullet, global_position, dir)

func _on_GunTimer_timeout():
	can_shoot = true

func take_damage(damage):
	HEALTH -= damage
	if HEALTH <= 0:
		$CollisionShape2D.disabled = true
		die()

func die():
	emit_signal("died")
	queue_free()